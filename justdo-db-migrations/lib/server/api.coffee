_.extend JustdoDbMigrations.prototype,
  _immediateInit: ->
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
    stopScript:
      type: Function
    minimum_version:
      type: String
  registerMigrationScript: (migration_script_id, options) ->
    {cleaned_val} =
      JustdoHelpers.simpleSchemaCleanAndValidate(
        @_registerMigrationScriptSchema,
        options or {},
        {self: @, throw_on_error: true}
      )
    {runScript, stopScript, minimum_version} = cleaned_val

    if not @registered_migration_scripts?
      @registered_migration_scripts = []

    if APP.justdo_system_records.wereLteVersionInstalled minimum_version
      @registered_migration_scripts.push
        id: migration_script_id
        jobInit: runScript
        jobStop: stopScript

    return
