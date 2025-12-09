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
  
  removeRecord: (id) ->
    check id, String

    @system_records_collection.remove({_id: id})

    return

  _maintainBuiltinSystemRecords: ->
    # Maintain installed-versions

    if not (app_version = process.env?.APP_VERSION)?
      return

    if not JustdoSystemRecords.semver_regex.test app_version
      @logger.warn "System record installed-versions weren't updated, unknown format found in env var APP_VERSION: #{app_version}"

      return

    if not @system_records_collection.findOne({_id: "installed-versions", full: app_version}, {fields: {_id: 1}})?
      collection = @system_records_collection

      query = {_id: "installed-versions"}
      update =
        $addToSet:
          semver: app_version.match(JustdoSystemRecords.semver_regex)[0]
          full: app_version
      options =
        upsert: true

      APP.justdo_analytics.logMongoRawConnectionOp(collection._name, "update", query, update, options)
      collection.rawCollection().update query, update, options, Meteor.bindEnvironment (err) ->
        if err?
          console.error "@_maintainBuiltinSystemRecords failed"

        return

    return

  wereLteVersionInstalled: (version) ->
    # Return true if we find in the installed-versions system-record under the semver array that a version was
    # installed that is less then or equal to the version arg provided.
    # 
    # Version is expected to be of https://semver.org/ format, other inputs will be rejected with an exception.
    #
    # E.g. of valid version: "v3.113.20", "3.113.20". 
    # E.g. of invalid version: "v3.113.20-stm"
    
    if not JustdoSystemRecords.semver_regex_strict.test version
      throw @_error "invalid-argument", "Input should be in the format of semetic versioning https://semver.org/"
    
    # Fetch the installed-versions document
    installed_version_doc = @system_records_collection.findOne({_id: "installed-versions"}, {fields: {semver: 1}})
    
    if not installed_version_doc?.semver?
      return false

    # Check if any installed version is less than or equal to the target version
    installed_version_lte_target_version = _.find installed_version_doc.semver, (installed_version) ->
      return JustdoHelpers.compareSemanticVersions(installed_version, version) <= 0

    return installed_version_lte_target_version?

