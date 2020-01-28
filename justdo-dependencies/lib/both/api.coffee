_.extend JustdoDependencies.prototype,
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

  isPluginInstalledOnProjectDoc: (project_doc) ->
    return APP.projects.isPluginInstalledOnProjectDoc(JustdoDependencies.project_custom_feature_id, project_doc)

  getProjectDocIfPluginInstalled: (project_id) ->
    return @projects_collection.findOne({_id: project_id, "conf.custom_features": JustdoDependencies.project_custom_feature_id})

  getTaskDependenciesSeqId: (task_doc) ->
    if not (dependencies = task_doc[JustdoDependencies.dependencies_field_id])?
      return []

    if not _.isString(dependencies)
      return []

    dependencies = dependencies.trim()

    if dependencies == ""
      return []

    return dependencies.split(/\s*,\s*/).map(Number)

  getTaskDependenciesTasksObjs: (task_doc, options, user_id) ->
    options = _.extend {fields: null}, options

    project_id = task_doc.project_id
    seq_ids = @getTaskDependenciesSeqId(task_doc)

    if _.isEmpty(seq_ids)
      return []

    query = 
      project_id: project_id
      seqId: {$in: seq_ids}

    if user_id?
      query.users = user_id
    
    query_options = {}

    if (fields = options.fields)?
      query_options.fields = fields

    return APP.collections.Tasks.find(query, query_options).fetch()

  getTasksObjsBlockingTask: (task_doc, options, user_id) ->
    options = _.extend {fields: {}}, options

    options.fields = _.extend options.fields, {_id: 1, seqId: 1, state: 1, "#{JustdoDependencies.dependencies_field_id}": 1} # take these minimum fields

    blocking_tasks_objs = []

    for dependency_obj in @getTaskDependenciesTasksObjs(task_doc, options, user_id)
      if dependency_obj.state not in JustdoDependencies.non_blocking_tasks_states
        blocking_tasks_objs.push dependency_obj

    return blocking_tasks_objs