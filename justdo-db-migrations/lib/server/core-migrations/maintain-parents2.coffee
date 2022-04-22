common_batched_migration_options =
  starting_condition_interval_between_checks: 1000 * 60

  startingCondition: ->
    return (APP.justdo_db_migrations.isMigrationScriptMarkedAsComplete "add-parents2") and (APP.justdo_db_migrations.isMigrationScriptMarkedAsComplete "check-parents2")

  mark_as_completed_upon_batches_exhaustion: false
  delay_before_checking_for_new_batches: 1000 * 3

  delay_between_batches: 1000
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
      _raw_updated_date:
        $gte: new Date APP.justdo_system_records.getRecord("maintain-parents2-tasks").previous_checkpoint + 1
      _raw_removed_date: null

    query_options =
      fields:
        parents: 1
        parents2: 1
        _raw_updated_date: 1

    return {query, query_options}

  batchProcessor: (tasks_collection_cursor) ->
    self = @
    current_checkpoint = APP.justdo_system_records.getRecord("maintain-parents2-tasks").previous_checkpoint + 1
    num_processed = 0

    tasks_collection_cursor.forEach (task) ->
      num_processed += 1
      current_checkpoint = Math.max current_checkpoint, task._raw_updated_date

      if not APP.projects._grid_data_com.checkParents2 task
        self.logWarning "The two parent objects of #{task._id} are not consistent. A new parents2 object is being created."
        APP.projects._grid_data_com._addParents2 task

      return

    APP.collections.SystemRecords.upsert "maintain-parents2-tasks",
      $set:
        previous_checkpoint: current_checkpoint

    return num_processed

APP.justdo_db_migrations.registerMigrationScript "maintain-parents2", JustdoDbMigrations.commonBatchedMigration(common_batched_migration_options)
