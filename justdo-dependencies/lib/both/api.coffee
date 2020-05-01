_.extend JustdoDependencies.prototype,
  _bothImmediateInit: ->
    # @_bothImmediateInit runs before the specific env's @_immediateInit()

    self = @
  
    @alertOrThrow = (error_type)->
      if Meteor.isClient
        JustdoSnackbar.show
          text: self._errors_types[error_type]
      else
        throw self._error error_type
      return

    return

  _bothDeferredInit: ->
    # @_bothDeferredInit runs before the specific env's @_deferredInit()

    # Add here code that should run, in the Server and Client, after the JS
    # tick in which we created the object instance.

    if @destroyed
      return

    return
  
  checkDependenciesFormatBeforeUpdate: (doc, field_names, modifier, options) ->
    # note: checkDependenciesFormatBeforeUpdate works on the human friendly field

    if JustdoDependencies.dependencies_field_id not in field_names
      return true
      
    new_set_values = modifier["$set"]?[JustdoDependencies.dependencies_field_id]
    new_push_value = modifier["$push"]?[JustdoDependencies.dependencies_field_id]
    if not new_set_values and not new_push_value
      return true
  
    existing_dependencies = doc[JustdoDependencies.dependencies_field_id] or []
  
    checkForInfiniteLoop = (tasks_ids, new_dependency_seq_id) ->
      # in this check we don't check for the existing of the dependency, but just if it creates an infinite loop
      new_dependency_doc = JD.collections.Tasks.findOne {seqId: new_dependency_seq_id, project_id: doc.project_id}
      if new_dependency_doc
        # if the doc is already listed, get out
        if new_dependency_doc._id in tasks_ids
          return true
        tasks_ids.push new_dependency_doc._id
        if (new_dependencies_seq = new_dependency_doc[JustdoDependencies.dependencies_field_id])?
          for new_dependency_seq in new_dependencies_seq
            if checkForInfiniteLoop(tasks_ids, new_dependency_seq) == true
              return true
        tasks_ids.pop()
      # if we didn't find the dependent task, it's okay...
      return false
  
    collect_parents_ids = (task_id, all_parents_set) ->
      if task_id == "0"
        return
      if(task_parents = JD.collections.Tasks.findOne(task_id)?.parents)?
        for parent_id in Object.keys(task_parents)
          if parent_id != "0"
            collect_parents_ids parent_id, all_parents_set
            all_parents_set.add parent_id
      return
  
    collect_children_ids = (task_id, all_children_set) ->
      _.each JD.collections.Tasks.find({"parents.#{task_id}": {$exists: true}}).fetch(), (child_doc) ->
        collect_children_ids child_doc._id, all_children_set
        all_children_set.add child_doc._id
        return
      return
    
      if(task_parents = JD.collections.Tasks.findOne(task_id)?.parents)
        for parent_id in Object.keys(task_parents)
          if parent_id != "0"
            collect_parents_ids parent_id, all_parents_set
            all_parents_set.add parent_id
      return
  
    parentDependency = (task_id, dependency) ->
      all_parents = new Set()
      collect_parents_ids(task_id, all_parents)
      found_one = false
      _.each JD.collections.Tasks.find({_id: {$in: Array.from(all_parents)}}).fetch(), (parent_doc) ->
        if parent_doc.seqId == dependency
          found_one = true
      if found_one
        return true
      return false
  
    child_dependency = (task_id, dependency) ->
      all_children = new Set()
      collect_children_ids(task_id, all_children)
      found_one = false
      _.each JD.collections.Tasks.find({_id: {$in: Array.from(all_children)}}).fetch(), (child_doc) ->
        if child_doc.seqId == dependency
          found_one = true
      if found_one
        return true
      return false
      
    if new_push_value
      if new_push_value in existing_dependencies
        @alertOrThrow "dependency-already-exists"
        return false
    
      if new_push_value == doc.seqId
        @alertOrThrow "self-dependency"
        return false
    
      if not (JD.collections.Tasks.findOne {seqId: new_push_value, project_id: doc.project_id})
        @alertOrThrow "dependent-task-not-found"
        return false
    
      if checkForInfiniteLoop([doc._id], new_push_value)
        @alertOrThrow "Infinite-dependency-loop"
        return false
    
      if parentDependency doc._id, new_push_value
        @alertOrThrow "parent-dependency"
        return false
    
      if child_dependency doc._id, new_push_value
        @alertOrThrow "child-dependency"
        return false
  
    if new_set_values
      for new_set_value in new_set_values
        if (not doc[JustdoDependencies.dependencies_field_id]?) or (new_set_value not in doc[JustdoDependencies.dependencies_field_id])
          # dealing with only new ones...
          if new_set_value == doc.seqId
            @alertOrThrow "self-dependency"
            return false
        
          if not (JD.collections.Tasks.findOne {seqId: new_set_value, project_id: doc.project_id, _raw_removed_date: {$exists: false}})
            @alertOrThrow "dependent-task-not-found"
            return false
        
          if checkForInfiniteLoop([doc._id], new_set_value)
            @alertOrThrow "Infinite-dependency-loop"
            return false
        
          if parentDependency doc._id, new_set_value
            @alertOrThrow "parent-dependency"
            return false
        
          if child_dependency doc._id, new_set_value
            @alertOrThrow "child-dependency"
            return false
  
    return true # end of check dependencies format and integrity

  isPluginInstalledOnProjectDoc: (project_doc) ->
    return APP.projects.isPluginInstalledOnProjectDoc(JustdoDependencies.project_custom_feature_id, project_doc)

  getProjectDocIfPluginInstalled: (project_id) ->
    return @projects_collection.findOne({_id: project_id, "conf.custom_features": JustdoDependencies.project_custom_feature_id})

  getTaskDependenciesSeqId: (task_doc) ->
    if not (dependencies = task_doc[JustdoDependencies.dependencies_field_id])?
      return []

    if not _.isArray(dependencies)
      return []

    return dependencies

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
  
  dependentTasksBySeqNumber: (task_doc) ->
    if (dependencies = task_doc[JustdoDependencies.dependencies_field_id])?
      return dependencies
    return []