APP.justdo_db_migrations.registerMigrationScript "check-parents2",
  runScript: ->
    batch_size = 300

    # The two var below are solely for logging progress
    initial_affected_docs_count = 0
    num_processed = 0

    query =
      _id:
        $nin: APP.justdo_system_records.getRecord("checked-parents2-tasks")?.checked_task_ids or []
      parents:
        $exists: true
      parents2:
        $exists: true
      _raw_removed_date: null

    options =
      fields:
        parents: 1
        parents2: 1
      limit: batch_size

    tasks_collection_cursor = APP.collections.Tasks.find(query, options)
    @logProgress "Total documents to be checked: #{initial_affected_docs_count = tasks_collection_cursor.count()}"

    while tasks_collection_cursor.count() > 0 and @isAllowedToContinue()
      checked_task_ids = []
      tasks_ids_with_problems = []

      tasks_collection_cursor.forEach (task) ->
        {parents, parents2} = task
        for parent2_obj in parents2
          if parents[parent2_obj?.parent]?.order isnt parent2_obj?.order
            console.error "The two parent objects of #{task._id} are not consistent."
            tasks_ids_with_problems.push task._id
            break

        checked_task_ids.push task._id
        APP.collections.SystemRecords.upsert "checked-parents2-tasks", {$addToSet: {checked_task_ids: {$each:  checked_task_ids}, tasks_ids_with_problems: {$each: tasks_ids_with_problems}}}

        num_processed += 1

      @logProgress "#{num_processed}/#{initial_affected_docs_count} documents checked"
      query._id.$nin = APP.justdo_system_records.getRecord("checked-parents2-tasks")?.checked_task_ids or []
      tasks_collection_cursor = APP.collections.Tasks.find(query, options)

    return

  haltScript: ->
    @logProgress "Halted"
    @disallowToContinue()

    return

  run_if_lte_version_installed: null
