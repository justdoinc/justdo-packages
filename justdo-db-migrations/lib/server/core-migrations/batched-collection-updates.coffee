job_batch_size = 1

common_batched_migration_options =
  mark_as_completed_upon_batches_exhaustion: false
  delay_before_checking_for_new_batches: 1000 * 3

  delay_between_batches: 1000
  batch_size: 10000

  collection: APP.collections.DBMigrationBatchedCollectionUpdates

  static_query: false
  queryGenerator: ->
    # FETCH_TASKS_BY_RAW_UPDATED_DATE_INDEX
    query =
      process_status:
        $in: ["pending", "in-progress"]

    query_options =
      fields: undefined

    return {query, query_options}

  batchProcessor: (cursor) ->
    self = @
    num_processed = 0
    
    cursor.forEach (job) ->
      # XXX check if user has access ?
      new_processed = job.process_status_details.processed + job_batch_size
      
      if new_processed > job.ids_to_update.length
        new_processed = job.ids_to_update.length
      ids_to_update = job.ids_to_update.slice(job.process_status_details.processed, new_processed)
      modifier = JSON.parse(job.modifier)
      
      job_update = {
        $set:
          "process_status_details.processed": new_processed
      }

      if job.process_status_details.processed + job_batch_size >= job.ids_to_update.length
        job_update.$set.process_status = "done"
        job_update.$set["process_status_details.closed_at"] = new Date()
      else if job.process_status == "pending"
        job_update.$set.process_status = "in-progress"
        job_update.$set["process_status_details.started_at"] = new Date()
      
      type_def = APP.justdo_db_migrations.batched_collection_updates_types[job.type]

      if type_def.use_raw_collection == true
        type_def.collection.rawCollection().update {
          _id:
            $in: ids_to_update
        }, modifier, {multi: true}, (err) ->
          delete job_update.$set["process_status_details.processed"]
          job_update.$set.process_status = "error"
          job_update.$set["process_status_details.closed_at"] = new Date()
          job_update.$set["process_status_details.error_data"] = JSON.stringify(err)

      else 
        try
          type_def.collection.update
            _id:
              $in: ids_to_update
          , modifier, {multi: true}
        catch e
          delete job_update.$set["process_status_details.processed"]
          job_update.$set.process_status = "error"
          job_update.$set["process_status_details.closed_at"] = new Date()
          job_update.$set["process_status_details.error_data"] = JSON.stringify(err)
          
      num_processed += ids_to_update.length
      APP.collections.DBMigrationBatchedCollectionUpdates.update job._id, job_update

      return

    return num_processed

APP.justdo_db_migrations.registerMigrationScript "batched-collection-updates", JustdoDbMigrations.commonBatchedMigration(common_batched_migration_options)