_.extend JustdoDbMigrations.prototype,
  _immediateInit: ->
    @registered_migration_scripts = {}

    @running_scripts_ids = {}

    @batched_collection_updates_types = {}

    return

  _deferredInit: ->
    if @destroyed
      return

    @_registerCoreCollectionUpdatesTypes()

    # Defined in methods.coffee
    @_setupMethods()

    # Defined in publications.coffee
    @_setupPublications()

    # Defined in collections-hooks.coffee
    @_setupCollectionsHooks()

    # Defined in collections-indexes.coffee
    @_ensureIndexesExists()

    # Defined in jobs.coffee
    @_setupJobs()

    return

  _registerMigrationScriptSchema: new SimpleSchema
    runScript:
      type: Function
    haltScript:
      type: Function
    run_if_lte_version_installed:
      type: String
      optional: true # If not provided, will be called in all envs
  registerMigrationScript: (migration_script_id, options) ->
    {cleaned_val} =
      JustdoHelpers.simpleSchemaCleanAndValidate(
        @_registerMigrationScriptSchema,
        options or {},
        {self: @, throw_on_error: true}
      )
    {runScript, haltScript, run_if_lte_version_installed} = cleaned_val

    if not run_if_lte_version_installed? or APP.justdo_system_records.wereLteVersionInstalled run_if_lte_version_installed
      @registered_migration_scripts[migration_script_id] =
        id: migration_script_id
        runScript: runScript
        haltScript: haltScript
        allowed_to_continue: null
    else
      @logger.info "NOTE #{migration_script_id} migration script skipped. A version smaller than: #{run_if_lte_version_installed} weren't installed in this environment."

    return

  _getCommonThis: (migration_script_id) ->
    self = @

    common_script_this =
      logProgress: (...message) ->
        message.unshift("[#{migration_script_id}]")
        return self.logger.info.apply self.logger, message

      logWarning: (...message) ->
        message.unshift("[#{migration_script_id}] Warning:")
        return self.logger.warn.apply self.logger, message

    return common_script_this

  _getRunScriptThis: (migration_script_id) ->
    self = @

    run_script_this = @_getCommonThis(migration_script_id)

    _.extend run_script_this,
      markAsCompleted: ->
        self._markMigrationScriptAsNotRunning(migration_script_id)
        update =
          $addToSet:
            completed_migrations:
              migration_id: migration_script_id
              completed_time: new Date()
        APP.collections.SystemRecords.upsert "completed-migrations", update
        @logProgress("Marked as completed")
        return
      isAllowedToContinue: ->
        return self.registered_migration_scripts[migration_script_id].allowed_to_continue
      halt: ->
        if self.isMigrationScriptMarkedAsNotRunning(migration_script_id)
          self.runMigrationScriptHaltScript(migration_script_id)

        return

    return run_script_this

  _getHaltScriptThis: (migration_script_id) ->
    self = @

    halt_script_this = @_getCommonThis(migration_script_id)

    _.extend halt_script_this, {} 

    return halt_script_this

  _markMigrationScriptAsRunning: (migration_script_id) ->
    @running_scripts_ids[migration_script_id] = true

    return

  _markMigrationScriptAsNotRunning: (migration_script_id) ->
    delete @running_scripts_ids[migration_script_id]

    return

  isMigrationScriptMarkedAsNotRunning: (migration_script_id) ->
    return @running_scripts_ids[migration_script_id]?

  isMigrationScriptMarkedAsComplete: (migration_script_id) ->
    query =
      _id: "completed-migrations"
      "completed_migrations.migration_id": migration_script_id
    return APP.collections.SystemRecords.findOne(query, {fields: {_id: 1}})?

  runMigrationScriptRunScript: (migration_script_id) ->
    if not migration_script_id of @registered_migration_scripts
      throw @_error "invalid-argument", "Unkown migration_script_id #{migration_script_id}"

    if @isMigrationScriptMarkedAsNotRunning(migration_script_id)
      throw @_error "invalid-argument", "runMigrationScriptRunScript was called for a migration script that is already running: #{migration_script_id}"

    if @isMigrationScriptMarkedAsComplete(migration_script_id)
      @logger.info "Migration script \"#{migration_script_id}\" has been executed before. Skipping."
      return

    migration_script_def = @registered_migration_scripts[migration_script_id]
    migration_script_def.allowed_to_continue = true

    run_script_this = @_getRunScriptThis(migration_script_id)

    @_markMigrationScriptAsRunning(migration_script_id)
    @logger.info "Run migration script: #{migration_script_id}."
    
    # For the runScript it is possible that the developer of a migration script
    # might write a pseudo-blocking while loops that will finish only when the script
    # will complete its run, for that reason, it is critical to call in defer
    # to allow runMigrationScriptRunScript to finish and other processes to continue.
    #
    # (By pseudo-blocking, I mean processes that looks like blocking, but actually aren't
    # really thanks to Fibers).
    Meteor.defer =>
      try
        migration_script_def.runScript.call(run_script_this)
      catch e
        @logger.error "Failed to run runScript of migration script #{migration_script_id}", e

        @_markMigrationScriptAsNotRunning(migration_script_id)
      return

    return

  runMigrationScriptHaltScript: (migration_script_id) ->
    if not migration_script_id of @registered_migration_scripts
      throw @_error "invalid-argument", "Unkown migration_script_id #{migration_script_id}"

    if not @isMigrationScriptMarkedAsNotRunning(migration_script_id)
      throw @_error "invalid-argument", "runMigrationScriptHaltScript was called for a migration script that isn't running: #{migration_script_id}"

    migration_script_def = @registered_migration_scripts[migration_script_id]

    halt_script_this = @_getHaltScriptThis(migration_script_id)

    @logger.info "Halt migration script: #{migration_script_id}."
    @registered_migration_scripts[migration_script_id].allowed_to_continue = false
    migration_script_def.haltScript.call(halt_script_this)
    @_markMigrationScriptAsNotRunning(migration_script_id)

    return

  runAllMigrationScripts: ->
    if _.isEmpty @registered_migration_scripts
      @logger.info "No registered migration script found."
      return

    for migration_script_id, migration_script_def of @registered_migration_scripts
      try
        @runMigrationScriptRunScript(migration_script_id)
      catch e
        @logger.error "Failed to run runScript of migration script #{migration_script_id}", e

        @_markMigrationScriptAsNotRunning(migration_script_id)

    return

  haltAllRunningMigrationScripts: ->
    for migration_script_id of @running_scripts_ids
      try
        @runMigrationScriptHaltScript(migration_script_id)
      catch e
        @logger.error "Failed to halt haltScript of migration script #{migration_script_id}", e

    return

  _registerBatchedCollectionUpdatesTypeOptionsSchema: new SimpleSchema
    collection:
      type: Mongo.Collection
    use_raw_collection:
      type: Boolean
      optional: true
    data_schema: # The schema of the job's data.
      type: SimpleSchema
    modifiersGenerator: # a function of the form `(data, perform_as) ->` it gets the job data and performing user.
                        # Should return *an array* of modifiers that we'll run on the documents of the job.
                        # Each modifier will run in a sparate call to the db
                        #
                        # IMPORTANT:
                        #
                        # For modifiers that are applied on the Tasks collection,
                        # the api will add the raw fields for you, in case that use_raw_collection
                        # is set to true - you don't need to worry about them.
      type: Function
      optional: false
    afterModifiersExecutionOps: # a function of the form `(ids_to_update, data, perform_as) ->`
                                # if provided, will be called after a successful execution of the queries
                                # provided by modifiersGenerator
      type: Function
      optional: true
    jobsGatekeeper: # an optional function of the form `(options) ->`, if provided will further validate that the job is permitted in terms
                    # of data provided and security. Note: schema validation for data provided is done regardless and isn't necessary here.
                    # options is of the form of @_registerBatchedCollectionUpdatesJobOptionsSchema, i.e the validated options provided
                    # to @registerBatchedCollectionUpdatesJob()
                    # Returned value is ignored - throw an error to reject the job.
      type: Function
      optional: true
  registerBatchedCollectionUpdatesType: (type_id, options) ->
    check type_id, String

    {cleaned_val} =
      JustdoHelpers.simpleSchemaCleanAndValidate(
        @_registerBatchedCollectionUpdatesTypeOptionsSchema,
        options,
        {self: @, throw_on_error: true}
      )
    options = cleaned_val

    @batched_collection_updates_types[type_id] = options

    return


  # Simple schema turned out to be too expensive for too big workload e.g 20k+ ids to update
  # _registerBatchedCollectionUpdatesJobOptionsSchema: new SimpleSchema
  #   data:
  #     type: Object
  #     blackbox: true
  #   ids_to_update:
  #     type: [String]
  #   user_id: # If not provided or is null/undefined - regarded as a system initiated job
  #     type: String
  #     optional: true
  _registerBatchedCollectionUpdatesJobCheckStructure:
    data: Object
    ids_to_update: [String]
    user_id: Match.Maybe(String)
  registerBatchedCollectionUpdatesJob: (type, options) ->
    check type, String
    check options, @_registerBatchedCollectionUpdatesJobCheckStructure

    if not (update_type_def = @batched_collection_updates_types[type])?
      throw @_error "batch-collection-update-type-not-supported", "Unknown batch collection update type: #{type}"

      return

    {cleaned_val} =
      JustdoHelpers.simpleSchemaCleanAndValidate(
        update_type_def.data_schema,
        options.data,
        {self: @, throw_on_error: true}
      )
    clean_and_validated_data = cleaned_val

    clean_and_validated_options = _.extend {}, options, {data: clean_and_validated_data}

    if _.isFunction(update_type_def.jobsGatekeeper)
      update_type_def.jobsGatekeeper(clean_and_validated_options)

    # Use rawCollection to avoid any collectino2, simple schema, hooks, etc. that might be turn out to be too expensive.
    job_id = JustdoHelpers.pseudoBlockingRawCollectionInsertInsideFiber APP.collections.DBMigrationBatchedCollectionUpdates, 
      created_by: options.user_id
      type: type
      data: clean_and_validated_data
      ids_to_update: options.ids_to_update
      process_status: "pending"
      process_status_details:
        total: options.ids_to_update.length
        processed: 0
        created_at: new Date()

    return job_id

  terminateBatchedCollectionUpdatesJob: (job_id, user_id) ->
    check job_id, String
    check user_id, String
    APP.collections.DBMigrationBatchedCollectionUpdates.update {_id: job_id, created_by: user_id},
      $set:
        process_status: "terminated"
        "process_status_details.closed_at": new Date()
        "process_status_details.terminated_by": user_id

    return

  getUsersRecentBatchedOpsCursor: (user_id) ->
    closed_time_ttl = 1000 * 60 * 5
    cursor = APP.collections.DBMigrationBatchedCollectionUpdates.find(
      {
        created_by: user_id,
        $or: [
          {process_status: {$in: ["pending", "in-progress"]}},
          {"process_status_details.closed_at": {$gte: JustdoHelpers.getDateMsOffset(-1 * closed_time_ttl)}}
        ]
      }
    , {sort: {"process_status_details.created_at": 1}, fields: {_id: 1, data: 1, type: 1, process_status: 1, process_status_details: 1}})

    return cursor
