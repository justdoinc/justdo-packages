batch_size = 300

APP.justdo_db_migrations.registerMigrationScript "add-parents2",
  runScript: ->
    # The two var below are solely for logging progress
    initial_affected_docs_count = 0
    num_processed = 0

    query =
      parents2:
        $exists: false

    options =
      fields:
        parents: 1
      limit: batch_size

    tasks_collection_cursor = APP.collections.Tasks.find(query, options)
    @logProgress "Total documents to be updated: #{initial_affected_docs_count = tasks_collection_cursor.count()}"

    while tasks_collection_cursor.count() > 0 and @allowedToContinue()
      tasks_collection_cursor.forEach (task) ->
        {_id, parents} = task
        parents2 = []
        for parent_id, order_obj of parents
          parents2.push {parent: "#{parent_id}", order: order_obj.order}

        num_processed += APP.collections.Tasks.update _id, {$set: {parents2: parents2}}

      @logProgress "#{num_processed}/#{initial_affected_docs_count} documents updated"

    # Check if all documents are updated.
    if tasks_collection_cursor.count() is 0
      @markAsCompleted()

  haltScript: ->
    @logProgress "Halted"
    @disallowToContinue()

    return

  run_if_lte_version_installed: null # In semver if needed, the leading "v" is optional
