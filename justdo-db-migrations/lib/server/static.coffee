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
      label: "Migration function to be called, should return the Number of processed documents"
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

    onBatchesExaustion:
      label: "Relevant only if mark_as_completed_upon_batches_exhaustion is false, will run once we can't find more items to process, before beginning the 'delay_before_checking_for_new_batches'"
      type: Function
      optional: true

    # Default true
    mark_as_completed_upon_batches_exhaustion:
      label: "Should this migration mark itself as completed upon completion"
      type: Boolean
      optional: true
      defaultValue: true

    # Miliseconds, relevant only if mark_as_completed_upon_batches_exhaustion is false
    # This is the time that we will wait if the last batch had 0 results.
    delay_before_checking_for_new_batches:
      label: "Interval between checks for new migration batches."
      type: SimpleSchema.Integer
      optional: true
      defaultValue: 1000 * 30  # 30 seconds default retry delay

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

        if query_options?.jd_analytics_skip_logging isnt false
          query_options.jd_analytics_skip_logging = true

        query_options.limit = options.batch_size
        res =
          cursor: options.collection.find(query, query_options)
          count: -> options.collection.find(query, _.omit(query_options, "limit")).count()
        
        return res
      
      scriptWrapper = ->
        cursor_res = getCursor()
        pending_migration_set_cursor = cursor_res.cursor

        # The two var below are solely for logging progress
        num_processed = 0
        if options.mark_as_completed_upon_batches_exhaustion
          initial_affected_docs_count = cursor_res.count()
          @logProgress "Total documents to be updated: #{initial_affected_docs_count}."
          expected_batches = Math.ceil(initial_affected_docs_count / options.batch_size)
          @logProgress "Expected batches: #{expected_batches}."
          @logProgress "Expected time to complete: #{Math.round((expected_batches * options.delay_between_batches) / 1000 / 60)} minutes."

        migration_functions_this = getMigrationFunctionsThis(@)

        if _.isFunction options.initProcedures
          options.initProcedures.call migration_functions_this

        waitDelayBetweenBatchesAndRunProcessBatchWrapper = =>
          @logProgress "Waiting #{options.delay_between_batches / 1000}sec before starting the next batch"
          batch_timeout = Meteor.setTimeout =>
            processBatchWrapper()
          , options.delay_between_batches

          return

        waitDelayBeforeCheckingForNewBatchesAndRunProcessBatchWrapper = =>
          # @logProgress "Waiting #{options.delay_before_checking_for_new_batches / 1000}sec before checking for new batches"
          if options.onBatchesExaustion?
            options.onBatchesExaustion()
          batch_timeout = Meteor.setTimeout =>
            processBatchWrapper()
          , options.delay_before_checking_for_new_batches

          return

        processBatchWrapper = =>
          try
            processBatch()
          catch e
            @logProgress "Error encountered, will try again in #{options.delay_before_checking_for_new_batches / 1000}sec", e

            waitDelayBeforeCheckingForNewBatchesAndRunProcessBatchWrapper()
            # Do not halt the script, some errors, like network issues might be resolved after a while
            # and we don't want to need to restart the server in such a case
            # @halt()

          return

        processBatch = =>
          if not @isAllowedToContinue()
            return

          if not options.static_query
            cursor_res = getCursor()
            pending_migration_set_cursor = cursor_res.cursor

          if cursor_res.count() == 0
            if options.mark_as_completed_upon_batches_exhaustion
              @markAsCompleted()

              runTerminationProcedures(@)

              return

            waitDelayBeforeCheckingForNewBatchesAndRunProcessBatchWrapper()
          else
            @logProgress "Start batch"

            num_processed += options.batchProcessor.call migration_functions_this, pending_migration_set_cursor

            if options.mark_as_completed_upon_batches_exhaustion
              @logProgress "#{num_processed}/#{initial_affected_docs_count} documents processed"
            else
              @logProgress "#{num_processed} documents processed"
              num_processed = 0

            waitDelayBetweenBatchesAndRunProcessBatchWrapper()

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

JustdoDbMigrations.docExpiryMigration = (options) ->
  {
    delay_between_batches,
    batch_size,
    collection, 
    ttl, 
    created_at_field,
    exec_interval,
    last_run_record_name, 
    batchProcessor
  } = options

  common_batched_migration_options =
    starting_condition_interval_between_checks: exec_interval

    startingCondition: ->
      # In the worst case, a server that took control in (exec_interval - 1) will expire documents in ((exec_interval * 2) - 1)
      last_run = APP.justdo_system_records.getRecord(last_run_record_name)?.value

      return not last_run? or (new Date() - last_run >= exec_interval)

    delay_between_batches: delay_between_batches
    batch_size: batch_size

    collection: collection

    queryGenerator: ->
      exp_date = new Date()
      exp_date.setMilliseconds(exp_date.getMilliseconds() - ttl)
      query =
        [created_at_field]:
          $lte: exp_date

      query_options =
        fields:
          _id: 1
    
      return {query, query_options}

    static_query: false

    mark_as_completed_upon_batches_exhaustion: false
    delay_before_checking_for_new_batches: exec_interval

    custom_options: {}

    initProcedures: ->
      return

    batchProcessor: batchProcessor or (cursor) ->
      expired_doc_ids = []
      cursor.forEach (doc) =>
        expired_doc_ids.push(doc._id)
        return

      collection.remove
        _id:
          $in: expired_doc_ids

      return expired_doc_ids.length

    onBatchesExaustion: ->
      APP.justdo_system_records.setRecord last_run_record_name,
        value: new Date()
      return

    terminationProcedures: ->
      return

  return JustdoDbMigrations.commonBatchedMigration(common_batched_migration_options)

JustdoDbMigrations.perpetualMaintainer = (options) ->
  batch_processor_ran = false
  margin_of_safety_if_batch_processor_didnt_run = Math.min(2 * 1000, options.exec_interval) # The minimum between the full interval and 2 seconds.

  if (delayed_updated_at_field = options.delayed_updated_at_field)?
    margin_of_safety_if_batch_processor_didnt_run += delayed_updated_at_field

  common_batched_migration_options =
    delay_between_batches: options.delay_between_batches
    batch_size: options.batch_size

    collection: options.collection

    queryGenerator: ->
      query = options.queryGenerator()

      if not (last_checkpoint = APP.justdo_system_records.getRecord(options.checkpoint_record_name)?.value)?
        last_checkpoint = JustdoHelpers.getEpochDate()

      query[options.updated_at_field] =
        $gte: last_checkpoint

      if (delayed_updated_at_field = options.delayed_updated_at_field)?
        lt_time = JustdoHelpers.getDateMsOffset(-1 * delayed_updated_at_field)
        query[options.updated_at_field].$lt = lt_time
      
      query_options =
        fields:
          _id: 1
          [options.updated_at_field]: 1

        sort:
          [options.updated_at_field]: 1

      if options.custom_fields_to_fetch?
        _.extend query_options.fields, options.custom_fields_to_fetch

      return {query, query_options}

    static_query: false

    mark_as_completed_upon_batches_exhaustion: false
    delay_before_checking_for_new_batches: options.exec_interval

    batchProcessor: (cursor) ->
      batch_processor_ran = true
      checkpoint_val = null
      num_processed = 0

      cursor.forEach (doc) =>
        num_processed += 1

        if options.customCheckpointValGenerator?
          checkpoint_val = options.customCheckpointValGenerator(doc)
        else
          checkpoint_val = doc[options.updated_at_field]

        options.batchProcessorForEach(doc)

        return

      if checkpoint_val?
        APP.justdo_system_records.setRecord options.checkpoint_record_name,
          value: checkpoint_val
        ,
          jd_analytics_skip_logging: true

      return num_processed

    onBatchesExaustion: ->
      if batch_processor_ran
        batch_processor_ran = false
      else
        # If we didn't find any document to process, just set the checkpoint to NOW - margin_of_safety_if_batch_processor_didnt_run
        # to reduce the amount of docs scanned next time.

        default_checkpoint = JustdoHelpers.getDateMsOffset(-1 * margin_of_safety_if_batch_processor_didnt_run)

        APP.justdo_system_records.setRecord options.checkpoint_record_name,
          value: default_checkpoint
        ,
          jd_analytics_skip_logging: true

      return

  return JustdoDbMigrations.commonBatchedMigration(common_batched_migration_options)
