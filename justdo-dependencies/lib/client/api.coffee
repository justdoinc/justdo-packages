_.extend JustdoDependencies.prototype,
  _immediateInit: ->
    return

  _deferredInit: ->
    if @destroyed
      return

    @registerConfigTemplate()
    @setupCustomFeatureMaintainer()

    return

  checkDependenciesFormatBeforeUpdate: (doc, field_names, modifier, options) ->
    if JustdoDependencies.dependencies_field_id not in field_names
      return true

    new_set_values = modifier["$set"]?[JustdoDependencies.dependencies_field_id]
    new_push_value = modifier["$push"]?[JustdoDependencies.dependencies_field_id]
    if not new_set_values and not new_push_value
      return true

    existing_dependencies = doc[JustdoDependencies.dependencies_field_id] or []

    checkForInfiniteLoop = (tasks_ids, new_dependency_seq_id) ->
      # in this check we don't check for the existing of the dependency, but just if it creates an infinite loop
      new_dependency_doc = JD.collections.Tasks.findOne {seqId: new_dependency_seq_id}
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
        JustdoSnackbar.show text: "This dependency already exists"
        return false

      if new_push_value == doc.seqId
        JustdoSnackbar.show text: "Task can't be dependent on itself"
        return false

      if not (JD.collections.Tasks.findOne {seqId: new_push_value})
        JustdoSnackbar.show text: "Task ##{new_push_value} not found."
        return false

      if checkForInfiniteLoop([doc._id], new_push_value)
        JustdoSnackbar.show text: "Infinite dependency loop identified, update reversed.."
        return false

      if parentDependency doc._id, new_push_value
        JustdoSnackbar.show text: "A task can't be dependant on any of its parents, update reversed.."
        return false

      if child_dependency doc._id, new_push_value
        JustdoSnackbar.show text: "A task can't be dependant on any of its child-tasks, update reversed.."
        return false


    if new_set_values
      for new_set_value in new_set_values
        if (not doc[JustdoDependencies.dependencies_field_id]?) or (new_set_value not in doc[JustdoDependencies.dependencies_field_id])
          # dealing with only new ones...
          if new_set_value == doc.seqId
            JustdoSnackbar.show text: "Task can't be dependent on itself"
            return false

          if not (JD.collections.Tasks.findOne {seqId: new_set_value})
            JustdoSnackbar.show text: "Task ##{new_set_value} not found."
            return false

          if checkForInfiniteLoop([doc._id], new_set_value)
            JustdoSnackbar.show text: "Infinite dependency loop identified, update reversed.."
            return false

          if parentDependency doc._id, new_set_value
            JustdoSnackbar.show text: "A task can't be dependant on any of its parents, update reversed.."
            return false

          if child_dependency doc._id, new_set_value
            JustdoSnackbar.show text: "A task can't be dependant on any of its child-tasks, update reversed.."
            return false

    return true

  setupCustomFeatureMaintainer: ->
    custom_feature_maintainer =
      APP.modules.project_page.setupProjectCustomFeatureOnProjectPage JustdoDependencies.project_custom_feature_id,
        installer: =>
          APP.justdo_project_pane.registerTab
            tab_id: "justdo-dependencies"
            order: 102
            tab_template: "justdo_project_dependencies"
            tab_label: "Dependencies"

          APP.modules.project_page.setupPseudoCustomField JustdoDependencies.dependencies_field_id,
            label: JustdoDependencies.dependencies_field_label
            field_type: JustdoDependencies.dependencies_field_type
            grid_visible_column: true
            grid_editable_column: true
            default_width: 100

          @collection_hook = APP.collections.Tasks.before.update (user_id, doc, field_names, modifier, options)=>
            return @checkDependenciesFormatBeforeUpdate doc, field_names, modifier, options

          return

        destroyer: =>
          APP.justdo_project_pane.unregisterTab "justdo-dependencies"

          APP.modules.project_page.removePseudoCustomFields JustdoDependencies.dependencies_field_id

          @collection_hook.remove()

          return

    @onDestroy =>
      custom_feature_maintainer.stop()

      return

    return

  tasksDependentF2S: (project_id, from_task_id, to_task_id) ->
    from_task = JD.collections.Tasks.findOne {_id: from_task_id, project_id: project_id}
    to_task = JD.collections.Tasks.findOne {_id: to_task_id, project_id: project_id}
    if from_task and to_task
      from_task_seqId = from_task.seqId

      if to_task[JustdoDependencies.dependencies_field_id] and from_task_seqId in to_task[JustdoDependencies.dependencies_field_id]
        return true
    return false


  addFinishToStartDependency: (project_id, from_task_id, to_task_id) ->
    from_task = JD.collections.Tasks.findOne {_id: from_task_id, project_id: project_id}
    to_task = JD.collections.Tasks.findOne {_id: to_task_id, project_id: project_id}
    if from_task and to_task
      from_task_seqId = from_task.seqId

      if to_task[JustdoDependencies.dependencies_field_id] and from_task_seqId in to_task[JustdoDependencies.dependencies_field_id]
        JustdoSnackbar.show
          text: "Tasks are already dependent"
          duration: 3000
          actionText: "Dismiss"
          onActionClick: =>
            JustdoSnackbar.close()
            return
        return

      # connect the tasks, and present an undo option
      ret = JD.collections.Tasks.update
          _id: to_task_id
        ,
          $push:
            "#{JustdoDependencies.dependencies_field_id}": from_task_seqId

      if ret
        JustdoSnackbar.show
          text: "Task ##{to_task.seqId} is now dependent on Task ##{from_task.seqId}"
          duration: 5000
          actionText: "Undo"
          onActionClick: =>
            JD.collections.Tasks.update
              _id: to_task_id
            ,
            $pull:
              "#{JustdoDependencies.dependencies_field_id}": from_task_seqId
            JustdoSnackbar.close()
            return
    return


  removeFinishToStartDependency: (project_id, from_task_id, to_task_id) ->
    from_task = JD.collections.Tasks.findOne {_id: from_task_id, project_id: project_id}
    to_task = JD.collections.Tasks.findOne {_id: to_task_id, project_id: project_id}
    if from_task and to_task
      from_task_seqId = from_task.seqId

      if to_task[JustdoDependencies.dependencies_field_id] and from_task_seqId not in to_task[JustdoDependencies.dependencies_field_id]
        JustdoSnackbar.show
          text: "Tasks are not dependent"
          duration: 3000
          actionText: "Dismiss"
          onActionClick: =>
            JustdoSnackbar.close()
            return
        return

      # disconnect the tasks, and present an undo option
      JD.collections.Tasks.update
        _id: to_task_id
      ,
        $pull:
          "#{JustdoDependencies.dependencies_field_id}": from_task_seqId

      JustdoSnackbar.show
        text: "Dependency removed"
        duration: 5000
        actionText: "Undo"
        onActionClick: =>
          JD.collections.Tasks.update
            _id: to_task_id
          ,
            $push:
              "#{JustdoDependencies.dependencies_field_id}": from_task_seqId
          JustdoSnackbar.close()
          return
    return
