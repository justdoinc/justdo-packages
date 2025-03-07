_.extend CustomJustdoSaveDefaultView.prototype,
  _immediateInit: ->
    return

  _deferredInit: ->
    if @destroyed
      return

    # Defined in methods.coffee
    @_setupMethods()

    # Defined in publications.coffee
    @_setupPublications()

    # Defined in allow-deny.coffee
    @_setupAllowDenyRules()

    # Defined in collections-hooks.coffee
    @_setupCollectionsHooks()

    # Defined in collections-indexes.coffee
    @_ensureIndexesExists()

    @_registerAllowedConfs()

    return


  _registerAllowedConfs: ->
    Projects.registerAllowedConfs
      "#{CustomJustdoSaveDefaultView.project_conf_key}":
        require_admin_permission: true
        value_matcher: String
        allow_change: true
        allow_unset: true

    return

  performInstallProcedures: (project_doc, user_id) ->
    # Called when plugin installed for project project_doc._id
    console.log "Plugin #{JustdoFormulaFields.project_custom_feature_id} installed on project #{project_doc._id}"

    return

  performUninstallProcedures: (project_doc, user_id) ->
    # Called when plugin uninstalled from project project_doc._id

    # Note, isn't called on project removal

    console.log "Plugin #{JustdoFormulaFields.project_custom_feature_id} removed from project #{project_doc._id}"

    return
