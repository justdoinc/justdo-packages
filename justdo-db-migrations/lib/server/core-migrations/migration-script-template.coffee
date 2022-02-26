batch_size = 300

APP.justdo_db_migrations.registerMigrationScript "migration-script-name",
  runScript: ->
    # The two var below are solely for logging progress
    initial_affected_docs_count = 0
    num_processed = 0

    # The query should exclude the documents that are migratred,
    # as runScript() will be called again when the host server loses control then gain back control
    query = {}

    options =
      fields: {}
      limit: batch_size

    collection_cursor = APP.collections.CollectionName.find(query, options)
    @logProgress "Total documents to be updated: #{initial_affected_docs_count = collection_cursor.count()}"

    while collection_cursor.count() > 0 and @allowedToContinue()
      # Do stuffs here
      # Remember to increase num_processed
      @logProgress "#{num_processed}/#{initial_affected_docs_count} documents updated"

    # Check if all documents are updated.
    if collection_cursor.count() is 0
      @markAsCompleted()

  haltScript: ->
    @logProgress "Halted"
    @disallowToContinue()

    return

  run_if_lte_version_installed: null # In semver if needed, the leading "v" is optional
