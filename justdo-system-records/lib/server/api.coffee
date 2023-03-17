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

  setRecord: (id, doc, options) ->
    check id, String
    if options?
      check options.jd_analytics_skip_logging, Boolean

    if not doc?
      doc = {}

    @system_records_collection.upsert id, doc, {jd_analytics_skip_logging: options?.jd_analytics_skip_logging}

    return

  getRecord: (id) ->
    check id, String

    return @system_records_collection.findOne(id, {jd_analytics_skip_logging: true})

  _maintainBuiltinSystemRecords: ->
    # Maintain installed-versions

    if not (app_version = process.env?.APP_VERSION)?
      return

    if not JustdoSystemRecords.semver_regex.test app_version
      @logger.warn "System record installed-versions weren't updated, unknown format found in env var APP_VERSION: #{app_version}"

      return

    if not @system_records_collection.findOne({_id: "installed-versions", full: app_version}, {fields: {_id: 1}})?
      @system_records_collection.upsert "installed-versions",
        $addToSet:
          semver: app_version.match(JustdoSystemRecords.semver_regex)[0]
          full: app_version

    return

  wereLteVersionInstalled: (version) ->
    # Return true if we find in the installed-versions system-record under the semver array that a version was
    # installed that is less then or equal to the version arg provided.
    # 
    # Version is expected to be of https://semver.org/ format, other inputs will be rejected with an exception.
    #
    # E.g. of valid version: "v3.113.20", "3.113.20". 
    # E.g. of invalid version: "v3.113.20-stm"
    
    version = version.trim()
    if not JustdoSystemRecords.semver_regex_strict.test version
      throw @_error "invalid-argument", "Input should be in the format of semetic versioning https://semver.org/"

    if version[0] isnt "v"
      version = "v" + version

    query =
      _id: "installed-versions"
      semver:
        $lte: version

    return @system_records_collection.findOne(query, {fields: {_id: 1}})?
