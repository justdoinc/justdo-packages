APP.justdo_db_migrations.registerMigrationScript "check-parents2",
  runScript: ->
    batch_size = 1000

    # The two var below are solely for logging progress
    initial_affected_docs_count = 0
    num_processed = 0

    query =
      parents:
        $ne: null
      parents2:
        $ne: null
      _raw_removed_date: null

    if (previous_checkpoint = APP.justdo_system_records.getRecord("checked-parents2-tasks")?.previous_checkpoint)?
      query._id = {$gt: previous_checkpoint}

    options =
      fields:
        parents: 1
        parents2: 1
      sort:
        _id: 1
      limit: batch_size

    tasks_collection_cursor = APP.collections.Tasks.find(query, options)

    initial_affected_docs_count = tasks_collection_cursor.count()
    @logProgress "Total documents to be checked: #{initial_affected_docs_count}"

    while tasks_collection_cursor.count() > 0 and @isAllowedToContinue()
      tasks_ids_with_problems = []
      current_checkpoint = null

      tasks_collection_cursor.forEach (task) ->
        num_processed += 1
        current_checkpoint = task._id

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

      @logProgress "#{num_processed}/#{initial_affected_docs_count} documents checked"

      query._id = {$gt: current_checkpoint}

      tasks_collection_cursor = APP.collections.Tasks.find(query, options)


    if tasks_collection_cursor.count() is 0
      @markAsCompleted()

    return

  haltScript: ->
    return

  run_if_lte_version_installed: null
