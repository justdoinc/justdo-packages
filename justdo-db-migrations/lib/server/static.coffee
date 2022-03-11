commonBatchedMigrationOptionsSchema = new SimpleSchema
    delay_between_batches:
      label: "Delay between batches"
      type: SimpleSchema.Integer

    batch_size:
      label: "" # XXX
      type: SimpleSchema.Integer

    collection:
      type: "skip-type-check"

    run_if_lte_version_installed:
      label: "Version installed that require the migration"
      type: String
      optional: true

    pending_migration_set_query:
      label: "Query of documents for migraiton"
      type: Object
      blackbox: true

    pending_migration_set_query_options:
      label: "Query options of documents for migraiton"
      type: Object
      blackbox: true
      optional: true

    custom_options:
      label: "Custom options for migration script"
      type: Object
      blackbox: true
      optional: true

    initProcedures:
      label: "" # XXX
      type: Function
      blackbox: true
      optional: true

    batchProcessor:
      label: "Migration function to be called"
      type: Function
      blackbox: true

    terminationProcedures:
      label: "" # XXX
      type: Function
      blackbox: true
      optional: true

JustdoDbMigrations.commonBatchedMigration = (options) ->
  {cleaned_val} =
    JustdoHelpers.simpleSchemaCleanAndValidate(
      commonBatchedMigrationOptionsSchema,
      options,
      {self: @, throw_on_error: true}
    )

  options = cleaned_val

  shared_obj = {}
  getMigrationFunctionsThis = (original_this) ->
    migration_functions_this = Object.create(original_this)

    return _.extend migration_functions_this,
      collection: options.collection
      options: options
      shared: shared_obj # XXX

  runTerminationProcedures = (caller_this) ->
    migration_functions_this = getMigrationFunctionsThis(caller_this)
    if _.isFunction options.terminationProcedures
      options.terminationProcedures.call migration_functions_this

    return

  batch_timeout = null
  clearTimeout = ->
    if batch_timeout?
      Meteor.clearTimeout batch_timeout
      batch_timeout = null

      @logProgress "Batch processing timeout cleared"

    return

  migration_script_obj =
    runScript: ->
      pending_migration_set_query_options = _.extend {}, options.pending_migration_set_query_options, {limit: options.batch_size}
      pending_migration_set_cursor = options.collection.find(options.pending_migration_set_query, pending_migration_set_query_options)

      # The two var below are solely for logging progress
      initial_affected_docs_count = 0
      num_processed = 0

      initial_affected_docs_count = pending_migration_set_cursor.count() # Note: count ignores limit
      @logProgress "Total documents to be updated: #{initial_affected_docs_count}."
      expected_batches = Math.ceil(initial_affected_docs_count / options.batch_size)
      @logProgress "Expected batches: #{expected_batches}."
      @logProgress "Expected time to complete: #{Math.round((expected_batches * options.delay_between_batches) / 1000 / 60)} minutes."

      migration_functions_this = getMigrationFunctionsThis(@)

      if _.isFunction options.initProcedures
        options.initProcedures.call migration_functions_this

      processBatchWrapper = =>
        try
          processBatch()
        catch e
          @logProgress "Error found halt the script", e

          @halt()

        return

      processBatch = =>
        if not @isAllowedToContinue()
          return

        if pending_migration_set_cursor.count() == 0
          @markAsCompleted()

          runTerminationProcedures(@)

          return

        @logProgress "Start batch"

        num_processed += options.batchProcessor.call migration_functions_this, pending_migration_set_cursor

        @logProgress "#{num_processed}/#{initial_affected_docs_count} documents updated"

        @logProgress "Waiting #{options.delay_between_batches / 1000}sec before starting the next batch"
        batch_timeout = Meteor.setTimeout =>
          processBatchWrapper()
        , options.delay_between_batches

        return

      Meteor.defer ->
        # To avoid running in the original tick that called the necessary db-migrations, defer the run
        processBatchWrapper()

        return

      return

    haltScript: ->
      clearTimeout.call(@)

      runTerminationProcedures(@)

      return

    run_if_lte_version_installed: options.run_if_lte_version_installed

  return migration_script_obj
