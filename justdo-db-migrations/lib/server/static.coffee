# NPM dependencies check
cron_parser = Npm.require "cron-parser"

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
    # Can return:
    #   - true: condition met, start processing
    #   - false: condition not met, check again after starting_condition_interval_between_checks
    #   - Number (ms): condition not met, check again after the returned number of milliseconds. Must be greater than 0.
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

    # If true, upon batches exhaustion (and after calling onBatchesExaustion if defined),
    # the migration will return to monitoring startingCondition instead of waiting delay_before_checking_for_new_batches.
    # This enables recurring scheduled behavior where the migration cycles between:
    # monitoring condition -> processing batches -> monitoring condition
    # Relevant only if mark_as_completed_upon_batches_exhaustion is false and startingCondition is set.
    #
    # IMPORTANT NOTE:
    #
    # If due to exception, we failed to process a batch, we will still use delay_before_checking_for_new_batches before re-trying. 
    # So note, that delay_before_checking_for_new_batches is used even when initialize_starting_condition_upon_exhaustion is set to true.
    initialize_starting_condition_upon_exhaustion:
      label: "Return to monitoring startingCondition after batches are exhausted"
      type: Boolean
      optional: true
      defaultValue: false

JustdoDbMigrations.commonBatchedMigration = (options) ->
  {cleaned_val} =
    JustdoHelpers.simpleSchemaCleanAndValidate(
      commonBatchedMigrationOptionsSchema,
      options,
      {self: @, throw_on_error: true}
    )
  options = cleaned_val

  if options.initialize_starting_condition_upon_exhaustion and not options.startingCondition?
    throw APP.justdo_db_migrations._error "invalid-options", "initialize_starting_condition_upon_exhaustion requires a startingCondition"

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
  clearBatchTimeout = ->
    if batch_timeout?
      Meteor.clearTimeout batch_timeout
      batch_timeout = null

      @logProgress "Batch processing timeout cleared"

    return

  check_starting_condition_timeout = null
  clearStartingConditionTimeout = ->
    if check_starting_condition_timeout?
      Meteor.clearTimeout check_starting_condition_timeout
      check_starting_condition_timeout = null

      @logProgress "Starting condition timeout cleared"

    return

  # Helper to evaluate startingCondition and determine next interval
  # Returns: {condition_met: Boolean, next_check_interval: Number (ms) or null}
  evaluateStartingCondition = (caller_this) ->
    migration_functions_this = getMigrationFunctionsThis(caller_this)
    result = options.startingCondition.call migration_functions_this
    
    if result is true
      return {condition_met: true, next_check_interval: null}
    else if _.isNumber(result)
      if result <= 0
        throw APP.justdo_db_migrations._error "invalid-options", "startingCondition must return a number greater than 0"
      # startingCondition returned a custom interval in ms
      return {condition_met: false, next_check_interval: result}
    else
      # result is false or any other falsy value
      return {condition_met: false, next_check_interval: options.starting_condition_interval_between_checks}

  # Start monitoring the startingCondition
  startConditionMonitoring = (caller_this, callback) ->
    checkCondition = ->
      if not caller_this.isAllowedToContinue()
        return

      {condition_met, next_check_interval} = evaluateStartingCondition(caller_this)
      
      if condition_met
        caller_this.logProgress "Starting condition met"
        callback()
      else
        caller_this.logProgress "Starting condition not met. Checking again in #{JustdoHelpers.msToHumanReadable next_check_interval}."
        check_starting_condition_timeout = Meteor.setTimeout checkCondition, next_check_interval

      return

    checkCondition()
    return

  migration_script_obj =
    runScript: ->
      self = @
      migration_functions_this = getMigrationFunctionsThis(self)

      getCursor = ->
        {query, query_options} = options.queryGenerator.call migration_functions_this

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
          @logProgress "Expected time to complete: #{JustdoHelpers.msToHumanReadable expected_batches * options.delay_between_batches}."

        if _.isFunction options.initProcedures
          options.initProcedures.call migration_functions_this

        waitDelayBetweenBatchesAndRunProcessBatchWrapper = =>
          @logProgress "Waiting #{JustdoHelpers.msToHumanReadable options.delay_between_batches} before starting the next batch"
          batch_timeout = Meteor.setTimeout =>
            processBatchWrapper()
            return
          , options.delay_between_batches

          return

        waitDelayBeforeCheckingForNewBatchesAndRunProcessBatchWrapper = =>
          if options.onBatchesExaustion?
            options.onBatchesExaustion.call migration_functions_this

          if options.initialize_starting_condition_upon_exhaustion
            # Return to monitoring startingCondition.
            # Call terminationProcedures to clean up resources created by initProcedures,
            # since initProcedures will be called again when the condition is next met.
            @logProgress "Batch processing complete, returning to monitoring mode (waiting for startingCondition to be met)"
            runTerminationProcedures(@)
            startConditionMonitoring self, ->
              scriptWrapper.call self
              return
          else
            # Original behavior: wait and check for new batches
            batch_timeout = Meteor.setTimeout =>
              processBatchWrapper()
              return
            , options.delay_before_checking_for_new_batches

          return

        processBatchWrapper = =>
          try
            processBatch()
          catch e
            @logProgress "Error encountered, will try again in #{JustdoHelpers.msToHumanReadable options.delay_before_checking_for_new_batches}", e

            # Note that in this particular case, we aren't 'Waiting for new Batches';
            # We are actually waiting in the hope that the issue that caused the error thrown
            # would get resolved by the 'waitDelay' time.
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
      
      if options.startingCondition?
        startConditionMonitoring self, callScriptWrapper
      else
        callScriptWrapper()

      return

    haltScript: ->
      clearBatchTimeout.call(@)
      clearStartingConditionTimeout.call(@)

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
      last_run = @getCheckpoint()

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
      @setCheckpoint(new Date())
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

      if not (last_checkpoint = @getCheckpoint())?
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
        @setCheckpoint(checkpoint_val)

      return num_processed

    onBatchesExaustion: ->
      if batch_processor_ran
        batch_processor_ran = false
      else
        # If we didn't find any document to process, just set the checkpoint to NOW - margin_of_safety_if_batch_processor_didnt_run
        # to reduce the amount of docs scanned next time.

        default_checkpoint = JustdoHelpers.getDateMsOffset(-1 * margin_of_safety_if_batch_processor_didnt_run)

        @setCheckpoint(default_checkpoint)

      return

  return JustdoDbMigrations.commonBatchedMigration(common_batched_migration_options)

JustdoDbMigrations.removeIndexMigration = (options) ->
  removeIndexOptionsSchema = new SimpleSchema
    index_id:
      label: "Index identifier/name to remove"
      type: String

    collection:
      label: "Collection from which to remove the index"
      type: "skip-type-check"

    run_if_lte_version_installed:
      label: "Version installed that require the migration"
      type: String
      optional: true

  {cleaned_val} =
    JustdoHelpers.simpleSchemaCleanAndValidate(
      removeIndexOptionsSchema,
      options,
      {self: @, throw_on_error: true}
    )
  options = cleaned_val

  migration_script_obj =
    runScript: ->
      self = @

      raw_collection = options.collection.rawCollection()
      # check if index exists
      raw_collection.indexExists(options.index_id)
        .then (index_exists) =>
          if index_exists
            @logProgress "Attempting to remove index '#{options.index_id}' from collection"
            raw_collection.dropIndex(options.index_id)
              .then =>
                @logProgress "Successfully removed index '#{options.index_id}'"
                @markAsCompleted()
                return
              .catch (error) =>
                @logProgress "Error removing index '#{options.index_id}': #{error.message}", error
                @halt()
                return
          else
            @logProgress "Index '#{options.index_id}' does not exist. Marking as completed."
            @markAsCompleted()
          
          return
            
      return

    haltScript: ->
      # No cleanup needed for index removal
      return

    run_if_lte_version_installed: options.run_if_lte_version_installed

  return migration_script_obj

# Schema for registerDbCronjob options
registerDbCronjobOptionsSchema = new SimpleSchema
  id:
    label: "Unique identifier for the cronjob"
    type: String

  cron_expression:
    # Cron expression format (POSIX/Vixie cron standard):
    #
    # ┌────────────── minute (0-59)
    # │ ┌──────────── hour (0-23)
    # │ │ ┌────────── day of month (1-31)
    # │ │ │ ┌──────── month (1-12 or JAN-DEC)
    # │ │ │ │ ┌────── day of week (0-7 or SUN-SAT, where 0 and 7 are Sunday)
    # │ │ │ │ │
    # * * * * *
    #
    # Special characters:
    #   * - any value
    #   , - value list separator (e.g., 1,3,5)
    #   - - range (e.g., 1-5)
    #   / - step values (e.g., */15 for every 15 minutes)
    #
    # Examples:
    #   "*/2 * * * *"     - every 2 minutes
    #   "0 9 * * 1-5"     - 9 AM on weekdays
    #   "0 0 1 * *"       - midnight on the 1st of each month
    #   "0 */6 * * *"     - every 6 hours
    #   "30 4 1,15 * *"   - 4:30 AM on the 1st and 15th of each month
    label: "Cron expression (POSIX/Vixie cron standard)"
    type: String

  persistent:
    # If persistent is false:
    #   - Calculate the next scheduled time from NOW and wait until then
    #   - Do NOT check if we should run right now (even if past a scheduled time)
    #
    # If persistent is true:
    #   - Run if the last scheduled occurrence is not marked as completed in the DB
    #   - If no record exists in the DB, treat as if it already ran (initialize the record)
    label: "Whether to run missed executions on startup"
    type: Boolean
    defaultValue: false

  tz:
    # IANA timezone identifier (e.g., "America/New_York", "Europe/London", "Asia/Jerusalem")
    # See: https://en.wikipedia.org/wiki/List_of_tz_database_time_zones
    label: "Timezone for cron expression evaluation"
    type: String
    defaultValue: "UTC"

  common_batch_migration_options:
    # Options to pass to commonBatchedMigration.
    # Note: `startingCondition` will be ignored as it is constructed from the cron options.
    label: "Options for commonBatchedMigration"
    type: Object
    blackbox: true

JustdoDbMigrations.registerDbCronjob = (options) ->
  # registerDbCronjob: A cron-based scheduling wrapper around commonBatchedMigration
  #
  # This function creates a migration script that:
  # 1. Evaluates a cron expression to determine when to run
  # 2. Supports persistent mode (run missed executions) and non-persistent mode (skip to next)
  # 3. Uses system records to track last run times
  # 4. Passes control to commonBatchedMigration for batch processing
  #
  # System record naming: "cron::<id>::last-run"
  # Record structure: { value: Date, completed: Boolean }

  {cleaned_val} =
    JustdoHelpers.simpleSchemaCleanAndValidate(
      registerDbCronjobOptionsSchema,
      options,
      {self: @, throw_on_error: true}
    )
  options = cleaned_val

  {id, cron_expression, persistent, tz, common_batch_migration_options} = options

  # Validate cron expression
  try
    cron_parser.parseExpression cron_expression, {tz: tz}
  catch e
    throw APP.justdo_db_migrations._error "invalid-options", "Invalid cron expression '#{cron_expression}': #{e.message}"

  # System record name for tracking last run
  last_run_record_name = "cron::#{id}::last-run"

  # Helper: Get the previous scheduled occurrence relative to a date
  getPreviousScheduledTime = (reference_date) ->
    try
      interval = cron_parser.parseExpression cron_expression,
        currentDate: reference_date
        tz: tz
      return interval.prev().toDate()
    catch e
      # If prev() fails (e.g., no previous occurrence), return null
      return null

  # Helper: Get the next scheduled occurrence relative to a date
  getNextScheduledTime = (reference_date) ->
    try
      interval = cron_parser.parseExpression cron_expression,
        currentDate: reference_date
        tz: tz
      return interval.next().toDate()
    catch e
      # If next() fails, return null
      return null

  # Helper: Get milliseconds until the next scheduled time
  getMsUntilNextScheduledTime = ->
    now = new Date()
    next_time = getNextScheduledTime(now)
    if not next_time?
      # Fallback to 1 hour if we can't determine next time
      return 60 * 60 * 1000
    return Math.max(1000, next_time.getTime() - now.getTime())

  # Create the startingCondition function based on cron options
  createStartingCondition = ->
    return ->
      now = new Date()
      record = APP.justdo_system_records.getRecord(last_run_record_name)

      # Get the previous scheduled time (the occurrence we might need to run)
      previous_scheduled_time = getPreviousScheduledTime(now)

      if not previous_scheduled_time?
        # No previous occurrence exists - wait for next
        return getMsUntilNextScheduledTime()

      if not record?
        # No record exists in the DB at all
        # Initialize the record as if it ran for both persistent and non-persistent modes.
        # For persistent: prevents running missed occurrences on first deployment
        #   (e.g., if a weekly email script is deployed mid-week, don't send the email)
        # For non-persistent: establishes a baseline so future scheduled times can be detected
        #   (without this, non-persistent scripts would never run because last_run_time would always be null)
        APP.justdo_system_records.setRecord last_run_record_name,
          value: previous_scheduled_time
          completed: true
        ,
          jd_analytics_skip_logging: true

        # Wait for the next occurrence
        return getMsUntilNextScheduledTime()

      last_run_time = record.value
      last_run_completed = record.completed

      if persistent
        # Persistent mode: run if the last scheduled occurrence wasn't completed
        if not last_run_time?
          # No last run time recorded, treat as needing to run
          return true

        # Check if we need to run:
        # 1. If previous_scheduled_time > last_run_time: This is a NEW scheduled occurrence
        # 2. If previous_scheduled_time == last_run_time AND not completed: Server crashed mid-execution
        if previous_scheduled_time > last_run_time
          # New scheduled occurrence we haven't run yet
          return true

        if (previous_scheduled_time.getTime() is last_run_time.getTime()) and not last_run_completed
          # Same occurrence but incomplete (server crashed mid-execution) - need to retry
          return true

        # Already ran and completed for this scheduled occurrence
        return getMsUntilNextScheduledTime()
      else
        # Non-persistent mode: skip missed executions on startup, but run future scheduled times
        if not last_run_time?
          # First time ever: don't run any missed occurrence, wait for the next one
          return getMsUntilNextScheduledTime()

        if previous_scheduled_time > last_run_time
          # A new scheduled time has arrived since our last run - execute now
          return true

        # We've already run for this period, wait for next
        return getMsUntilNextScheduledTime()

  # Build common_batch_migration_options, overriding startingCondition
  final_options = _.extend {}, common_batch_migration_options,
    # Override startingCondition with our cron-based one
    startingCondition: createStartingCondition()

    # Configure for recurring scheduled behavior
    mark_as_completed_upon_batches_exhaustion: false
    initialize_starting_condition_upon_exhaustion: true

    # Set a reasonable check interval based on cron expression
    # Default to 1 minute if not specified
    starting_condition_interval_between_checks: common_batch_migration_options.starting_condition_interval_between_checks or (60 * 1000)

  # Wrap onBatchesExaustion to update the system record
  original_on_batches_exaustion = common_batch_migration_options.onBatchesExaustion
  final_options.onBatchesExaustion = ->
    # Mark this scheduled occurrence as completed
    now = new Date()
    previous_scheduled_time = getPreviousScheduledTime(now)
    
    APP.justdo_system_records.setRecord last_run_record_name,
      value: previous_scheduled_time or now
      completed: true
    ,
      jd_analytics_skip_logging: true

    # Call the original onBatchesExaustion if provided
    if _.isFunction original_on_batches_exaustion
      original_on_batches_exaustion.call(@)

    return

  # Wrap initProcedures to mark the run as started (not completed yet)
  original_init_procedures = common_batch_migration_options.initProcedures
  final_options.initProcedures = ->
    # Mark this scheduled occurrence as started but not completed
    now = new Date()
    previous_scheduled_time = getPreviousScheduledTime(now)

    APP.justdo_system_records.setRecord last_run_record_name,
      value: previous_scheduled_time or now
      completed: false
    ,
      jd_analytics_skip_logging: true

    # Call the original initProcedures if provided
    if _.isFunction original_init_procedures
      original_init_procedures.call(@)

    return

  # Remove startingCondition from common_batch_migration_options if it was provided
  # (we've already set our own)
  if common_batch_migration_options.startingCondition?
    console.warn "registerDbCronjob: startingCondition in common_batch_migration_options is ignored; using cron-based scheduling instead"

  return JustdoDbMigrations.commonBatchedMigration(final_options)
