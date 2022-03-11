###
 # There are two ways to register a migration script.
 # For common migration script (i.e. Query for certain documents and insert/update back to the database),
 # the commonBatchedMigration helper can be used to generate the migration script object and reduce codes written.
###

#############################
# commonBatchedMigration ex #
#############################

common_batched_migration_options =
  run_if_lte_version_installed: "v3.3.3" # Defines applicable version for migration script, in semver. Optional.

  delay_between_batches: 1000 # Default is 1000

  collection: APP.collections.Tasks # The target collection for querying

  pending_migration_set_query: # Query for getting target docs
    parents2:
      $exists: false

  pending_migration_set_query_options: # Options for getting target docs.
    fields:
      parents: 1
    limit: 300 # Remember to add limit!

  custom_options: # Custom object to be passed to batchProcessor. Useful for storing data between loops (e.g. caching). Optional.
    abc: {}
    def: {}

  # The actual migrating function.
  # collection is the same collection passed above
  batchProcessor: (cursor, collection, options) ->
    num_processed = 0 # Remember to increment this value and return it to display progress.
    cursor.forEach (task) ->
      # ....do something
      num_processed += collection.update query, ops

    return num_processed

# Register the migration script using commonBatchedMigration and the options defined above
APP.justdo_db_migrations.registerMigrationScript "migration-script-name", JustdoDbMigrations.commonBatchedMigration(common_batched_migration_options)

###
  # If the upcoming migration does not fit into the use of commonBatchedMigration,
  # one can customize their migration script object as below
###

####################################
# Custom migration script obj demo #
####################################

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
