_.extend JustdoDbMigrations.prototype,
  _immediateInit: ->
    @registered_migration_scripts = {}

    @running_scripts_ids = {}

    return

  _deferredInit: ->
    if @destroyed
      return

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
    else
      @logger.info "NOTE #{migration_script_id} migration script skipped. A version smaller than: #{run_if_lte_version_installed} weren't installed in this environment."

    return

  _getCommonThis: (migration_script_id) ->
    self = @

    migration_script_def = @registered_migration_scripts[migration_script_id]

    common_script_this =
      logProgress: (message) ->
        return self.logger.info "[#{migration_script_id}] #{message}"

    return common_script_this

  _getRunScriptThis: (migration_script_id) ->
    self = @

    run_script_this = @_getCommonThis(migration_script_id)

    _.extend run_script_this,
      markAsCompleted: ->
        self._markMigrationScriptAsNotRunning(migration_script_id)

        @logProgress("Marked as completed")

        return
      allowedToContinue: ->
        return self.registered_migration_scripts[migration_script_id].allowed_to_continue

    return run_script_this

  _getHaltScriptThis: (migration_script_id) ->
    self = @

    halt_script_this = @_getCommonThis(migration_script_id)

    _.extend halt_script_this,
      disallowToContinue: ->
        self.registered_migration_scripts[migration_script_id].allowed_to_continue = false
        return

    return halt_script_this

  _markMigrationScriptAsRunning: (migration_script_id) ->
    @running_scripts_ids[migration_script_id] = true

    return

  _markMigrationScriptAsNotRunning: (migration_script_id) ->
    delete @running_scripts_ids[migration_script_id]

    return

  isMigrationScriptAsNotRunning: (migration_script_id) ->
    return @running_scripts_ids[migration_script_id]?

  runMigrationScriptRunScript: (migration_script_id) ->
    if not migration_script_id of @registered_migration_scripts
      throw @_error "invalid-argument", "Unkown migration_script_id #{migration_script_id}"

    if @isMigrationScriptAsNotRunning(migration_script_id)
      throw @_error "invalid-argument", "runMigrationScriptRunScript was called for a migration script that is already running: #{migration_script_id}"

    migration_script_def = @registered_migration_scripts[migration_script_id]
    migration_script_def.allowed_to_continue = true

    run_script_this = @_getRunScriptThis(migration_script_id)

    @_markMigrationScriptAsRunning(migration_script_id)
    @logger.info "Run migration script: #{migration_script_id}."
    migration_script_def.runScript.call(run_script_this)

    return

  runMigrationScriptHaltScript: (migration_script_id) ->
    if not migration_script_id of @registered_migration_scripts
      throw @_error "invalid-argument", "Unkown migration_script_id #{migration_script_id}"

    if not @isMigrationScriptAsNotRunning(migration_script_id)
      throw @_error "invalid-argument", "runMigrationScriptHaltScript was called for a migration script that isn't running: #{migration_script_id}"

    migration_script_def = @registered_migration_scripts[migration_script_id]

    halt_script_this = @_getHaltScriptThis(migration_script_id)

    @logger.info "Halt migration script: #{migration_script_id}."
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

    return

  haltAllRunningMigrationScripts: ->
    for migration_script_id of @running_scripts_ids
      try
        @runMigrationScriptHaltScript(migration_script_id)
      catch e
        @logger.error "Failed to halt haltScript of migration script #{migration_script_id}", e

    return
