common_batched_migration_options =
  starting_condition_interval_between_checks: 1000 * 60 # Miliseconds, relevant only if startingCondition is not null

  startingCondition: -> # default null
    return APP.justdo_db_migrations.isMigrationScriptMarkedAsComplete "add-parents2"

  mark_as_completed_upon_batches_exhaustion: true # default to true

  delay_between_batches: 1000 * 10
  batch_size: 10000

  collection: APP.collections.Tasks

  static_query: false # If set to false, the initial queryGenerator will be used to generate all the batches.
                      # If set to true we will call queryGenerator before every call to batchProcessor to create a new cursor
                      # for each batch with the returned query and query_options.
  queryGenerator: ->
    query =
      parents2:
        $ne: null
      parents:
        $ne: null
      corrupted_parents: null
      _raw_removed_date: null

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
    tasks_ids_with_problems = []
    current_checkpoint = null
    last_raw_updated_date = null
    num_processed = 0

    tasks_collection_cursor.forEach (task) ->
      num_processed += 1
      current_checkpoint = task._id
      last_raw_updated_date = Math.max last_raw_updated_date, task._raw_updated_date

      {parents, parents2} = task
      if _.size(parents) isnt _.size(parents2)
        console.error "The two parent objects of #{task._id} are not consistent."
        tasks_ids_with_problems.push task._id
        return

      for parent2_obj in parents2
        if parents[parent2_obj?.parent]?.order isnt parent2_obj?.order
          console.error "The two parent objects of #{task._id} are not consistent."
          tasks_ids_with_problems.push task._id
          break

      return

    APP.collections.SystemRecords.upsert "checked-parents2-tasks",
      $addToSet:
        tasks_ids_with_problems:
          $each: tasks_ids_with_problems
      $set:
        previous_checkpoint: current_checkpoint

    if last_raw_updated_date?
      APP.collections.SystemRecords.upsert "maintain-parents2-tasks",
        $set:
          previous_checkpoint: last_raw_updated_date

    return num_processed

APP.justdo_db_migrations.registerMigrationScript "check-parents2", JustdoDbMigrations.commonBatchedMigration(common_batched_migration_options)
