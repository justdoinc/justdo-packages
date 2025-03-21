APP.executeAfterAppLibCode ->
  common_batched_migration_options =
    starting_condition_interval_between_checks: 1000 * 60
    startingCondition: ->
      return APP.justdo_db_migrations.isMigrationScriptMarkedAsComplete "add-parents2"

    mark_as_completed_upon_batches_exhaustion: true

    delay_between_batches: 1000 * 10
    batch_size: 10000

    collection: APP.collections.Tasks

    static_query: false
    queryGenerator: ->
      query =
        parents2:
          $ne: null
        parents:
          $ne: null
        corrupted_parents: null
        _raw_removed_date: null

      # To avoid re-cheking the same batch of documents again and again, the cursor is sorted by the task id.
      # We store the last checked task id in system-records and use it as the starting point of the next batch of documents
      if (previous_checkpoint = APP.justdo_system_records.getRecord("checked-parents2-tasks")?.previous_checkpoint)?
        query._id =
          $gt: previous_checkpoint

      query_options =
        fields:
          parents: 1
          parents2: 1
          _raw_updated_date: 1
        sort:
          _id: 1

      return {query, query_options}

    batchProcessor: (tasks_collection_cursor) ->
      self = @
      # Note that current_checkpoint is being used by check-parents2(this script), and it holds task id
      current_checkpoint = null
      # Note that last_raw_updated_date is being used by maintain-parents2 ONLY, and it holds a date
      # After check-parents2 finished executing, the most recent _raw_updated_date will be saved into system-records
      # And used by maintain-parents2 to query for documents updated after being checked by check-parents2
      last_raw_updated_date = APP.justdo_system_records.getRecord("maintain-parents2-tasks")?.previous_checkpoint or null
      num_processed = 0

      tasks_collection_cursor.forEach (task) ->
        num_processed += 1
        current_checkpoint = task._id
        last_raw_updated_date = JustdoHelpers.datesMax(last_raw_updated_date, task._raw_updated_date)

        APP.projects._grid_data_com.ensureParents2 task, true

        return

      APP.justdo_system_records.setRecord "checked-parents2-tasks",
        previous_checkpoint: current_checkpoint
      ,
        jd_analytics_skip_logging: true

      if last_raw_updated_date?
        APP.justdo_system_records.setRecord "maintain-parents2-tasks",
          previous_checkpoint: last_raw_updated_date
        ,
          jd_analytics_skip_logging: true

      return num_processed

  APP.justdo_db_migrations.registerMigrationScript "check-parents2", JustdoDbMigrations.commonBatchedMigration(common_batched_migration_options)

  return