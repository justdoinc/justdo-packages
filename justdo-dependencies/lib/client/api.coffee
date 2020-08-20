_.extend JustdoDependencies.prototype,
  _immediateInit: ->
    return

  _deferredInit: ->
    if @destroyed
      return

    @registerConfigTemplate()
    @setupCustomFeatureMaintainer()

    return



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
            return @checkDependenciesFormatBeforeUpdate(doc, field_names, modifier, options)

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

  # todo - no need to have project id as a param on the client side. need to clean it up
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
        ,
          (err) ->
            if err?
              console.error err
              return
            # todo: reconsider if updating the dependent tasks should be part of the dependencies manager
            # or from the gantt object. There are considerations both ways. For now, leaving it here. This means that
            # if the gantt module is not loaded, then dependent tasks will not be automatically adjusted.
            if (grid_gantt = APP.justdo_grid_gantt)?
              grid_gantt.updateDependentTasks from_task_id
            return # end of callback

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
            ,
              (err) ->
                if err?
                  console.error err
                  return
                if (grid_gantt = APP.justdo_grid_gantt)?
                  grid_gantt.updateTaskStartDateBasedOnDependencies JD.collections.Tasks.findOne to_task_id
                return # end of callback
            
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
      ,
        (err) ->
          if err?
            console.error err
            return
            
          # todo: reconsider if updating the dependent tasks should be part of the dependencies manager
          # see same comment above
          if (grid_gantt = APP.justdo_grid_gantt)?
            dependent_obj = JD.collections.Tasks.findOne to_task_id
            grid_gantt.updateTaskStartDateBasedOnDependencies dependent_obj
          return # end of callback

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
          ,
            (err) ->
              if err?
                console.error err
                return
              if (grid_gantt = APP.justdo_grid_gantt)?
                grid_gantt.updateDependentTasks from_task_id
              return # end of callback
          
          JustdoSnackbar.close()
          return
    return

  heighestDependentsEndDate: (task_obj) ->
    dependencies = @getTaskDependenciesTasksObjs task_obj
    if dependencies.length == 0
      return null
    biggest_end_date = null
    for dependency in dependencies
      end_date = ""
      if dependency.end_date
        end_date = dependency.end_date
      else if dependency.due_date
        end_date = dependency.due_date

      if end_date
        if not biggest_end_date
          biggest_end_date = end_date
        else if end_date > biggest_end_date
          biggest_end_date = end_date

    return biggest_end_date
