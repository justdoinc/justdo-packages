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
    # FETCH_TASKS_BY_RAW_UPDATED_DATE_INDEX
    query =
      _raw_updated_date:
        $gte: getPreviousCheckpointOrEpochPlusOneMs()
      parents2:
        $ne: null
      parents:
        $ne: null
      corrupted_parents: null
      _raw_removed_date: null

    query_options =
      fields:
        parents: 1
        parents2: 1
        _raw_updated_date: 1

    console.log "HERE A000", {fibre_id: JustdoHelpers.getFiberId()}, {query, query_options}

    return {query, query_options}

  batchProcessor: (tasks_collection_cursor) ->
    self = @
    current_checkpoint = getPreviousCheckpointOrEpochPlusOneMs()
    num_processed = 0

    console.log "HERE A001", {fibre_id: JustdoHelpers.getFiberId()}, {current_checkpoint}

    tasks_collection_cursor.forEach (task) ->
      num_processed += 1
      current_checkpoint = JustdoHelpers.datesMax(current_checkpoint, task._raw_updated_date)

      console.log "HERE A010", {fibre_id: JustdoHelpers.getFiberId()}, {task}
      more_details = APP.collections.Tasks.findOne(task._id) # REMOVE ME! Added for testings
      console.log "HERE A010 - extra details :: ", more_details._id, " :: ", more_details.title, more_details
      APP.projects._grid_data_com.ensureParents2 task, true
      console.log "HERE A011", {fibre_id: JustdoHelpers.getFiberId()}, {task, title: APP.collections.Tasks.findOne(task._id, {fields: {title: 1}})}

      return

    console.log "HERE A002", {fibre_id: JustdoHelpers.getFiberId()}

    APP.collections.SystemRecords.upsert "maintain-parents2-tasks",
      $set:
        previous_checkpoint: current_checkpoint

    console.log "HERE A003", {fibre_id: JustdoHelpers.getFiberId()}

    return num_processed

APP.justdo_db_migrations.registerMigrationScript "maintain-parents2", JustdoDbMigrations.commonBatchedMigration(common_batched_migration_options)
