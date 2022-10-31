MAX_DOCS_UPDATES_PER_SECOND = JustdoDbMigrations.batched_collection_updates_max_docs_updates_per_second # Across all running jobs

TOTAL_IN_PROGRESS_JOBS_TO_HANDLE_PER_CYCLE = JustdoDbMigrations.batched_collection_updates_total_in_progress_jobs_to_handle_per_cycle

IMMEDIATE_PROCESS_THRESHOLD_DOCS = JustdoDbMigrations.batched_collection_updates_immediate_process_threshold_docs

TIMES_PER_SECOND_TO_CHECK_FOR_JOBS_FOR_IMMEDIATE_PROCESS = 5

SECOND_MS = 1000

console.log "HERE", {MAX_DOCS_UPDATES_PER_SECOND, TOTAL_IN_PROGRESS_JOBS_TO_HANDLE_PER_CYCLE, IMMEDIATE_PROCESS_THRESHOLD_DOCS}

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

      stats =
        pending:
          failed: 0
          modifiers_processed: 0
          partially_processed: 0
          fully_processed: 0
          docs_processed: 0
          docs_processed_actual: 0
        "in-progress":
          failed: 0
          modifiers_processed: 0
          partially_processed: 0
          fully_processed: 0
          docs_processed: 0
          docs_processed_actual: 0

      {jobs_to_process, in_progress_jobs_count} = determineJobsToProcess(cursor)
      jobs_to_process_ids = _.map(jobs_to_process, "_id")

      pending_jobs_max_docs_to_process_per_job = IMMEDIATE_PROCESS_THRESHOLD_DOCS
      in_progress_max_docs_to_process_per_job = 0
      if in_progress_jobs_count > 0
        in_progress_max_docs_to_process_per_job = Math.ceil(MAX_DOCS_UPDATES_PER_SECOND / in_progress_jobs_count)

      APP.collections.DBMigrationBatchedCollectionUpdates.find({_id: {$in: jobs_to_process_ids}}).forEach (job) ->
        new_processed = getNewProcessed(job, if job.process_status is "pending" then pending_jobs_max_docs_to_process_per_job else in_progress_max_docs_to_process_per_job)

        ids_to_update = job.ids_to_update.slice(job.process_status_details.processed, new_processed)

        now = new Date()

        job_update =
          $set:
            "process_status_details.processed": new_processed
            "process_status_details.last_processed": now

        if job.process_status == "pending"
          job_update.$set.started_at = now

        about_to_complete = false
        if new_processed >= job.ids_to_update.length
          job_update.$set.process_status = "done"
          job_update.$set["process_status_details.closed_at"] = now
          about_to_complete = true
        else if job.process_status == "pending"
          job_update.$set.process_status = "in-progress"

        failed = false
        setError = (code) ->
          failed = true
          job_update.$set.process_status = "error"
          job_update.$set["process_status_details.closed_at"] = now
          job_update.$set["process_status_details.error_data"] = {code}
          delete job_update.$set["process_status_details.processed"]
          delete job_update.$set["process_status_details.last_processed"]

          return

        modifiers_processed = 0
        actual_docs_processed = 0
        if not (type_def = APP.justdo_db_migrations.batched_collection_updates_types[job.type])?
          setError("unknown-job-type")
        else
          try
            selector = 
              _id:
                $in: ids_to_update

            mongo_update_options = 
              multi: true

            for modifier in type_def.modifiersGenerator(job.data, job.created_by)
              if type_def.use_raw_collection
                if type_def.collection is APP.collections.Tasks
                  # We take care of adding the raw fields for the users of this API.
                  APP.projects._grid_data_com._addRawFieldsUpdatesToUpdateModifier(modifier)

                {err, result} = JustdoHelpers.pseudoBlockingRawCollectionUpdateInsideFiber(type_def.collection, selector, modifier, mongo_update_options)
                
                if err?
                  throw new Error err

                modifiers_processed += 1
                actual_docs_processed += result.result.n
              else
                modifiers_processed += 1
                actual_docs_processed += type_def.collection.update selector, modifier, mongo_update_options
          catch e
            console.error "modifier-processing-failed", {modifier}, e
            setError("modifier-processing-failed")

        if _.isFunction type_def.afterModifiersExecutionOps
          try
            type_def.afterModifiersExecutionOps(ids_to_update, job.data, job.created_by)
          catch e
            console.error "after-modifiers-execution-ops-failed", e
            setError("after-modifiers-execution-ops-failed")

        if about_to_complete and (not failed) and _.isFunction(type_def.beforeJobMarkedAsDone)
          try
            type_def.beforeJobMarkedAsDone(job.data, job.created_by)
          catch e
            console.error "before-job-marked-as-done-procedures-failed", e
            setError("before-job-marked-as-done-procedures-failed")

        if failed
          stats[job.process_status].failed += 1
        else
          stats[job.process_status].modifiers_processed += modifiers_processed
          stats[job.process_status].docs_processed += ids_to_update.length
          stats[job.process_status].docs_processed_actual += actual_docs_processed
          if about_to_complete == true
            stats[job.process_status].fully_processed += 1
          else
            stats[job.process_status].partially_processed += 1

        APP.collections.DBMigrationBatchedCollectionUpdates.update(job._id, job_update)

        return

      console.info "[batched-collection-updates]", JSON.stringify(stats)

      return stats["pending"].docs_processed_actual + stats["in-progress"].docs_processed_actual

  APP.justdo_db_migrations.registerMigrationScript "batched-collection-updates", JustdoDbMigrations.commonBatchedMigration(common_batched_migration_options)

  return
