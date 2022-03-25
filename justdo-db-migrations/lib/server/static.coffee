commonBatchedMigrationOptionsSchema = new SimpleSchema
    delay_between_batches:
      label: "Delay between batches"
      type: SimpleSchema.Integer

    batch_size:
      label: "Size of migration per batch"
      type: SimpleSchema.Integer

    collection:
      type: "skip-type-check"

    run_if_lte_version_installed:
      label: "Version installed that require the migration"
      type: String
      optional: true

    queryGenerator:
      label: "Query and query options generator"
      type: Function

    # If set to false, the initial queryGenerator will be used to generate all the batches.
    # If set to true we will call queryGenerator before every call to batchProcessor to create a new cursor
    # for each batch with the returned query and query_options.
    static_query:
      label: "Should the cursor be updated before every batch"
      type: Boolean

    custom_options:
      label: "Custom options for migration script"
      type: Object
      blackbox: true
      optional: true

    initProcedures:
      label: "Migration script and variable init function"
      type: Function
      blackbox: true
      optional: true

    batchProcessor:
      label: "Migration function to be called"
      type: Function
      blackbox: true

    terminationProcedures:
      label: "Destroyer function for variables created in initProcedures"
      type: Function
      blackbox: true
      optional: true

    # Default null
    startingCondition:
      label: "Migration script starting condition"
      type: Function
      blackbox: true
      optional: true

    # Miliseconds, relevant only if startingCondition is set
    starting_condition_interval_between_checks:
      label: "Interval between checks for starting condition"
      type: SimpleSchema.Integer
      defaultValue: 1000 * 60

    # Default true
    mark_as_completed_upon_batches_exhaustion:
      label: "Should this migration mark itself as completed upon completion"
      type: Boolean
      optional: true
      defaultValue: true

    # Miliseconds, relevant only if mark_as_completed_upon_batches_exhaustion is false
    delay_before_checking_for_new_batches:
      label: "Interval between checks for new migration batches."
      type: SimpleSchema.Integer
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

  check_starting_condition_interval = null
  clearStartingConditionInterval = ->
    if check_starting_condition_interval?
      Meteor.clearInterval check_starting_condition_interval
      check_starting_condition_interval = null

      @logProgress "Starting condition interval cleared"

    return

  migration_script_obj =
    runScript: ->
      self = @

      getCursor = ->
        {query, query_options} = options.queryGenerator()
        query_options.limit = options.batch_size
        return options.collection.find(query, query_options)

      scriptWrapper = ->
        pending_migration_set_cursor = getCursor()

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

          if not options.static_query
            pending_migration_set_cursor = getCursor()

          if pending_migration_set_cursor.count() == 0
            if options.mark_as_completed_upon_batches_exhaustion
              @markAsCompleted()

              runTerminationProcedures(@)

              return

            @logProgress "Waiting #{options.delay_before_checking_for_new_batches / 1000}sec before checking for new batches"
            batch_timeout = Meteor.setTimeout =>
              processBatchWrapper()
            , options.delay_before_checking_for_new_batches
          else
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

      callScriptWrapper = -> scriptWrapper.call self
      if options.startingCondition? and not options.startingCondition()
        # If we got a startingCondition and it isn't met yet, then setup an interval to wait for it.
        check_starting_condition_interval = Meteor.setInterval ->
          if options.startingCondition()
            clearStartingConditionInterval.call(self)
            callScriptWrapper()
          else
            self.logProgress "Starting condition not met. Checking again in #{options.starting_condition_interval_between_checks / 1000} secs."
        , options.starting_condition_interval_between_checks
      else
        callScriptWrapper()

      return

    haltScript: ->
      clearTimeout.call(@)
      clearStartingConditionInterval.call(@)

      runTerminationProcedures(@)

      return

    run_if_lte_version_installed: options.run_if_lte_version_installed

  return migration_script_obj
