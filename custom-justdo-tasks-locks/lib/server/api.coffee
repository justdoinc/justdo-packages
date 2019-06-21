_.extend CustomJustdoTasksLocks.prototype,
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

  toggleTaskLockedState: (task_id, user_id) ->
    # We aren't testing for whether or not the project got the custom plugin installed
    # or not (won't have effect if the project is not having the plugin installed, so
    # it doesn't matter)

    check task_id, String

    if not (task_doc = @tasks_collection.getItemByIdIfUserBelong task_id, user_id)?
      throw @_error "unknown-task"

    if not (existing_locking_users = task_doc[CustomJustdoTasksLocks.locking_users_task_field])?
      existing_locking_users = []

    modifier = {}
    if user_id in existing_locking_users
      modifier.$pull = {"#{CustomJustdoTasksLocks.locking_users_task_field}": user_id}
    else
      modifier.$push = {"#{CustomJustdoTasksLocks.locking_users_task_field}": user_id}

    @tasks_collection.update(task_id, modifier)

    return
