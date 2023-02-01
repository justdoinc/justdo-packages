job_batch_size = 1

common_batched_migration_options =
  # starting_condition_interval_between_checks: 1000 * 60

  # startingCondition: ->
  #   return (APP.justdo_db_migrations.isMigrationScriptMarkedAsComplete "add-parents2") and (APP.justdo_db_migrations.isMigrationScriptMarkedAsComplete "check-parents2")

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
      else if job.process_status == "pending"
        job_update.$set.process_status = "in-progress"
      
      type_def = APP.justdo_db_migrations.batched_collection_updates_types[job.type]

      if type_def.use_raw_collection == true
        type_def.collection.rawCollection().update {
          _id:
            $in: ids_to_update
        }, modifier, {multi: true}, (err) ->
          delete job_update.$set["process_status_details.processed"]
          job_update.$set.process_status = "error"
      else 
        try
          type_def.collection.update
            _id:
              $in: ids_to_update
          , modifier, {multi: true}
        catch
          delete job_update.$set["process_status_details.processed"]
          job_update.$set.process_status = "error"
      
      num_processed += ids_to_update.length
      APP.collections.DBMigrationBatchedCollectionUpdates.update job._id, job_update

      return

    return num_processed

APP.justdo_db_migrations.registerMigrationScript "batched-collection-updates", JustdoDbMigrations.commonBatchedMigration(common_batched_migration_options)