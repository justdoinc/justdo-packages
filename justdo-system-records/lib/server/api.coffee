_.extend JustdoSystemRecords.prototype,
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

    @_maintainBuiltinSystemRecords()

    return

  setRecord: (id, doc) ->
    if not doc?
      doc = {}

    @system_records_collection.upsert id, doc

    return

  getRecord: (id) ->
    return @system_records_collection.findOne(id)

  _maintainBuiltinSystemRecords: ->
    # Maintain installed-versions

    # if (app_version = process.env?.APP_VERSION)?
    #   ensure version is included already in the installed-versions system-record otherwise add it.

    return

  wereLteVersionInstalled: (version) ->
    # Return true if we find in the installed-versions system-record under the semver array that a version was
    # installed that is less then or equal to the version arg provided.
    # 
    # Version is expected to be of https://semver.org/ format, other inputs will be rejected with an exception.
    #
    # E.g. of valid version: "v3.113.20", "3.113.20". 
    # E.g. of invalid version: "v3.113.20-stm"
    
    return