MAX_DOCS_UPDATES_PER_SECOND = 60 # Across all running jobs

TOTAL_IN_PROGRESS_JOBS_TO_HANDLE_PER_CYCLE = 3

IMMEDIATE_PROCESS_THRESHOLD_DOCS = 1 * 1000

TIMES_PER_SECOND_TO_CHECK_FOR_JOBS_FOR_IMMEDIATE_PROCESS = 5

SECOND_MS = 1000

getNewProcessed = (job, max_items_to_process) ->
  new_processed = job.process_status_details.processed + max_items_to_process
  if new_processed > job.ids_to_update.length
    new_processed = job.ids_to_update.length

  return new_processed

determineJobsToProcess = (cursor) ->
  jobs_to_process = []

  in_progress_jobs_count = 0

  try
    cursor.forEach (job) ->
      if job.process_status is "pending"
        jobs_to_process.push(job)
      else
        in_progress_jobs_count += 1
        jobs_to_process.push(job)

        if in_progress_jobs_count >= TOTAL_IN_PROGRESS_JOBS_TO_HANDLE_PER_CYCLE
          # Important note: we are ordering by process_status DESC, i.e p(ending) > i(n-progress) hence all the
          # pending jobs will come before the in-progress jobs - that's why we can safely break here, knowing
          # that there are no more pending jobs ahead of us in the forEach.

          throw new Error "max-in-progress-reached"

      return
  catch e
    if e.message isnt "max-in-progress-reached"
      throw e

  return {jobs_to_process, in_progress_jobs_count}

# Queue processing and starvation prevention mechanism:
#
# 1. TIMES_PER_SECOND_TO_CHECK_FOR_JOBS_FOR_IMMEDIATE_PROCESS times a minute we check for new
#    jobs (status "pending").
#  
#    For new jobs, regardless of whether or not they are bigger than IMMEDIATE_PROCESS_THRESHOLD_DOCS,
#    we process immediately up to IMMEDIATE_PROCESS_THRESHOLD_DOCS docs per job. The rest of the docs
#    will be handled by the in-progress mechanism.
#
#    We don't count the docs processed for new jobs against the minute's capacity.
#
#    Note, that it means that jobs with less than IMMEDIATE_PROCESS_THRESHOLD_DOCS docs will
#    be processed immediately in-full.
#
#    Motivation: for small jobs we want to bring the appearance of quick and responsive system.
#    It is only the big jobs that we want to manage congestion for.
#
# 2. Once a second we also fetch all the in-progress jobs:
#
#    We check the total docs from all the jobs that needs to be processed, if there are less than
#    MAX_DOCS_UPDATES_PER_SECOND in all the in-progres jobs we just run all of them.
#
#    Otherwise we pick up to the TOTAL_IN_PROGRESS_JOBS_TO_HANDLE_PER_CYCLE, in the order of last
#    processed ASC. This will create a round-robin for the capacity-giving for the in-progress jobs
#    queue, so none of them can starve. <- The motivation here, is to give each of the jobs picked
#    a significant enough capacity (we don't want for example to get to a point where each job gets
#    1 document to process, this will give the appearence of overly congested, stuck jobs).
#    
#    Let X be the amount of in-progress jobs we got in practice (0 <= X <= TOTAL_IN_PROGRESS_JOBS_TO_HANDLE_PER_CYCLE)
#    If X = 0 do nothing.
#    Otherwise we give ceil(X / MAX_DOCS_UPDATES_PER_SECOND) capacity to each in-progress task we handle in this
#    round.

last_time_in_progressed_processed = JustdoHelpers.getEpochDate()

APP.executeAfterAppLibCode ->
  common_batched_migration_options =
    mark_as_completed_upon_batches_exhaustion: false
    delay_before_checking_for_new_batches: SECOND_MS / TIMES_PER_SECOND_TO_CHECK_FOR_JOBS_FOR_IMMEDIATE_PROCESS # Delay between batches is short since for this db-migration we don't use delay_before_checking_for_new_batches as a tool for congestion management, and we want to quickly catch new requests to update
    delay_between_batches: SECOND_MS / TIMES_PER_SECOND_TO_CHECK_FOR_JOBS_FOR_IMMEDIATE_PROCESS # See comment for delay_before_checking_for_new_batches

    batch_size: 1000

    collection: APP.collections.DBMigrationBatchedCollectionUpdates

    static_query: false
    queryGenerator: ->
      query =
        process_status:
          $in: ["pending"]

      query_options =
        fields:
          _id: 1
          process_status: 1

      if JustdoHelpers.timeSinceDateMs(last_time_in_progressed_processed) > SECOND_MS
        # More than a second passed, new capacity available for processing in-progress jobs

        last_time_in_progressed_processed = new Date()

        query.process_status.$in.push "in-progress"

        query_options.sort = 
          "process_status": -1
          "process_status_details.last_processed": 1

      return {query, query_options}

    batchProcessor: (cursor) ->
      self = @

      pending_jobs_partially_processed = 0
      pending_jobs_fully_processed = 0
      in_progress_jobs_partially_processed = 0
      in_progress_jobs_fully_processed = 0

      {jobs_to_process, in_progress_jobs_count} = determineJobsToProcess(cursor)
      jobs_to_process_ids = _.map(jobs_to_process, "_id")

      pending_jobs_max_docs_to_process_per_job = IMMEDIATE_PROCESS_THRESHOLD_DOCS
      in_progress_max_docs_to_process_per_job = 0
      if in_progress_jobs_count > 0
        in_progress_max_docs_to_process_per_job = Math.ceil(MAX_DOCS_UPDATES_PER_SECOND / in_progress_jobs_count)

      APP.collections.DBMigrationBatchedCollectionUpdates.find({_id: {$in: jobs_to_process_ids}}).forEach (job) ->
        docs_to_process = getNewProcessed(job, if job.process_status is "pending" then pending_jobs_max_docs_to_process_per_job else in_progress_max_docs_to_process_per_job)

        new_processed = job.process_status_details.processed + docs_to_process

        ids_to_update = job.ids_to_update.slice(job.process_status_details.processed, new_processed)

        now = new Date()

        job_update =
          $set:
            "process_status_details.processed": new_processed
            "process_status_details.last_processed": now

        if job.process_status == "pending"          
          job_update.$set.started_at = now

        if new_processed >= job.ids_to_update.length
          job_update.$set.process_status = "done"
          job_update.$set["process_status_details.closed_at"] = now
        else if job.process_status == "pending"
          job_update.$set.process_status = "in-progress"

        setError = (code) ->
          job_update.$set.process_status = "error"
          job_update.$set["process_status_details.closed_at"] = now
          job_update.$set["process_status_details.error_data"] = {code}
          delete job_update.$set["process_status_details.processed"]
          delete job_update.$set["process_status_details.last_processed"]

          return

        if not (type_def = APP.justdo_db_migrations.batched_collection_updates_types[job.type])?
          setError("unknown-job-type")
        else
          # XXX
          # XXX continue here
          # XXX
          try
            console.log type_def.queryGenerator(ids_to_update, job.data, job.created_by)

            # type_def.collection.update
            #   _id:
            #     $in: ids_to_update
            # , modifier, {multi: true}
          catch e
            setError("query-processing-failed")

          # Attempt processing

        # console.log "WRITE", {job, job_update}

        return

      return

      # cursor.forEach (job) ->
      #   # XXX STOPPED HERE
      #   if job.process_status is "pending"
      #     max_items_to_process = IMMEDIATE_PROCESS_THRESHOLD_DOCS
      #   else
      #     # Think what to do for the in-progress
      #     1 + 1
      #  
      #   # job_update =
      #   #   $set:
      #   #     "process_status_details.processed": new_processed

      #   # if job.process_status_details.processed + job_batch_size >= job.ids_to_update.length
      #   #   job_update.$set.process_status = "done"
      #   #   job_update.$set["process_status_details.closed_at"] = new Date()
      #   # else if job.process_status == "pending"
      #   #   job_update.$set.process_status = "in-progress"
      #   #   job_update.$set["process_status_details.started_at"] = new Date()
        
        

      #   # if type_def.use_raw_collection == true
      #   #   APP.justdo_analytics.logMongoRawConnectionOp(@collection._name, "update", query, modifier, {multi: true})
      #   #   if type_def.collection._name == "tasks"
      #   #     @_addRawFieldsUpdatesToUpdateModifier(modifier)
      #   #   type_def.collection.rawCollection().update {
      #   #     _id:
      #   #       $in: ids_to_update
      #   #   }, modifier, {multi: true}, (err) ->
      #   #     delete job_update.$set["process_status_details.processed"]
      #   #     job_update.$set.process_status = "error"
      #   #     job_update.$set["process_status_details.closed_at"] = new Date()
      #   #     job_update.$set["process_status_details.error_data"] = JSON.stringify(err)

      #   # else 
      #   #   try
      #   #     type_def.collection.update
      #   #       _id:
      #   #         $in: ids_to_update
      #   #     , modifier, {multi: true}
      #   #   catch e
      #   #     delete job_update.$set["process_status_details.processed"]
      #   #     job_update.$set.process_status = "error"
      #   #     job_update.$set["process_status_details.closed_at"] = new Date()
      #   #     job_update.$set["process_status_details.error_data"] = JSON.stringify(err)
            
      #   # jobs_partially_or_fully_processed += ids_to_update.length
      #   # APP.collections.DBMigrationBatchedCollectionUpdates.update job._id, job_update

      #   return

      # return jobs_partially_or_fully_processed

  APP.justdo_db_migrations.registerMigrationScript "batched-collection-updates", JustdoDbMigrations.commonBatchedMigration(common_batched_migration_options)

  return
