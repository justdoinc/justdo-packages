_.extend CustomJustdoTasksLocks.prototype,
  _bothImmediateInit: ->
    # @_bothImmediateInit runs before the specific env's @_immediateInit()

    # Add here code that should run, in the Server and Client, during the JS
    # tick in which we create the object instance.

    return

  _bothDeferredInit: ->
    # @_bothDeferredInit runs before the specific env's @_deferredInit()

    # Add here code that should run, in the Server and Client, after the JS
    # tick in which we created the object instance.

    if @destroyed
      return

    return

  getProjectDocIfPluginInstalled: (project_id) ->
    return @projects_collection.findOne({_id: project_id, "conf.custom_features": CustomJustdoTasksLocks.project_custom_feature_id})

  isPluginInstalledOnProjectDoc: (project_doc) ->
    return APP.projects.isPluginInstalledOnProjectDoc(CustomJustdoTasksLocks.project_custom_feature_id, project_doc)

  getTaskDocLockingUsersIds: (task_doc) ->
    if not task_doc?
      return []

    if _.isString task_doc
      task_doc = APP.collections.Tasks.findOne(task_doc, {fields: {[CustomJustdoTasksLocks.locking_users_task_field]: 1}})
      
      if not task_doc?
        throw @_error "unknown-task"

    if not (locking_users_ids = task_doc[CustomJustdoTasksLocks.locking_users_task_field])?
      return []

    if not _.isArray locking_users_ids
      return []

    return locking_users_ids

  isUserAllowedToPerformRestrictedOperationsOnTaskDoc: (task_doc, user_id) ->
    locking_users_ids = @getTaskDocLockingUsersIds(task_doc)

    return locking_users_ids.length == 0 or (locking_users_ids.length == 1 and user_id in locking_users_ids)