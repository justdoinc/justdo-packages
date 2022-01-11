_.extend JustdoClipboardImport.prototype,
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

    return

  performInstallProcedures: (project_doc, user_id) ->
    # Called when plugin installed for project project_doc._id
    # console.log "Plugin #{JustdoFormulaFields.project_custom_feature_id} installed on project #{project_doc._id}"

    return

  performUninstallProcedures: (project_doc, user_id) ->
    # Called when plugin uninstalled from project project_doc._id

    # Note, isn't called on project removal

    # console.log "Plugin #{JustdoFormulaFields.project_custom_feature_id} removed from project #{project_doc._id}"

    return
  
  clearupTempImportId: (temp_import_ids, user_id) ->
    check temp_import_ids, [String]
    check user_id, String

    APP.collections.Tasks.update
      "jci:temp_import_id":
        $in: temp_import_ids
      users: user_id
    ,
      $unset:
        "jci:temp_import_id": ""
    ,
      multi: true
    
    return

  cleanUpDuplicatedManualValue: (task_ids, field_to_clear, user_id) ->
    @tasks_collection.update
      _id: 
        $in: task_ids
      users: user_id
    ,
      $unset:
        [field_to_clear]: ""
    ,
      multi: true

    return