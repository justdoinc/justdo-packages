_.extend JustdoResourcesAvailability.prototype,
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
    console.log "Plugin #{JustdoFormulaFields.project_custom_feature_id} installed on project #{project_doc._id}"

    return

  performUninstallProcedures: (project_doc, user_id) ->
    # Called when plugin uninstalled from project project_doc._id
    # Note, isn't called on project removal
    console.log "Plugin #{JustdoFormulaFields.project_custom_feature_id} removed from project #{project_doc._id}"

    return

  saveResourceAvailability: (executing_user_id, project_id, availability, user_id, task_id) ->
    check executing_user_id, String
    check project_id, String
    if user_id
      check user_id, String
    if task_id
      check task_id, String

    if not(projectObj = APP.collections.Projects.findOne({_id: project_id, "members.user_id": executing_user_id}))
      throw @_error "Project not found, or executing member not part of project"

    ra_field = JustdoResourcesAvailability.project_custom_feature_id
    all_resources = _.extend {}, projectObj[ra_field]
    key = project_id
    if user_id
      key += ":" + user_id
    if task_id
      key += ":" + task_id

    all_resources[key] = availability
    op = {$set: {"#{ra_field}": all_resources}}

    APP.collections.Projects.update({_id: project_id},op)

    return