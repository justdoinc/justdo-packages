getEpochDate = ->
  return new Date(0)

getDatePlusOneMs = (date) ->
  # Will use epoch if date is undefined/null or isn't a date
  if not _.isDate(date)
    date = getEpochDate()

    return date

  return new Date(date.valueOf() + 1)

getPreviousCheckpointOrEpoch = ->
  previous_checkpoint = APP.justdo_system_records.getRecord("maintain-parents2-tasks")?.previous_checkpoint

  if not _.isDate(previous_checkpoint)
    return getEpochDate()

  return previous_checkpoint

getPreviousCheckpointOrEpochPlusOneMs = ->
  return getDatePlusOneMs(getPreviousCheckpointOrEpoch())

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
        $gte: getPreviousCheckpointOrEpochPlusOneMs()
      _raw_removed_date: null

    query_options =
      fields:
        parents: 1
        parents2: 1
        _raw_updated_date: 1

    return {query, query_options}

  batchProcessor: (tasks_collection_cursor) ->
    self = @
    current_checkpoint = getPreviousCheckpointOrEpochPlusOneMs()
    num_processed = 0

    tasks_collection_cursor.forEach (task) ->
      num_processed += 1
      current_checkpoint = JustdoHelpers.datesMax(current_checkpoint, task._raw_updated_date)

      APP.projects._grid_data_com.ensureParents2 task, true

      return

    APP.collections.SystemRecords.upsert "maintain-parents2-tasks",
      $set:
        previous_checkpoint: current_checkpoint

    return num_processed

APP.justdo_db_migrations.registerMigrationScript "maintain-parents2", JustdoDbMigrations.commonBatchedMigration(common_batched_migration_options)
