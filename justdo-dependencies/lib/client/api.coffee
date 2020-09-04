TasksUpdatePreview = ->
  @modifiers = {}
  @preview = {}

  return @

_.extend TasksUpdatePreview.prototype,
  update: (org_doc, updates) ->
    task_id = org_doc._id
    # XXX see if need _.extend
    if not @preview[task_id]?
      @preview[task_id] = org_doc
    task = @preview[task_id]

    if not @modifiers[task_id]?
      @modifiers[task_id] =
        $set: {}
    modifier = @modifiers[task_id]

    for field, val of updates
      task[field] = val
      modifier.$set[field] = val
    
    return
  
  findOne: (task_id, fields) ->
    if @preview[task_id]?
      return @preview[task_id]
    return APP.collections.Tasks.findOne task_id,
      fields: fields

  updateDb: ->
    # XXX Creating a bulkUpdateTasksDates can increase the performance
    APP.justdo_dependencies.dependent_tasks_update_hook_enabled = false
    for task_id, modifier of @modifiers
      APP.collections.Tasks.update task_id, modifier
    APP.justdo_dependencies.dependent_tasks_update_hook_enabled = true

    return

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
    self = @
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
          
          APP.modules.project_page.setupPseudoCustomField JustdoDependencies.is_task_dates_frozen_pseudo_field_id,
              label: JustdoDependencies.is_task_dates_frozen_pseudo_field_label
              field_type: "select"
              grid_visible_column: true
              grid_editable_column: true
              default_width: 100
              field_options:
                select_options: [
                  {
                    option_id: "true"
                    label: "Yes"
                  }
                ]

          self.setupContextMenu()

          @collection_hook = APP.collections.Tasks.before.update (user_id, doc, field_names, modifier, options)=>
            return @checkDependenciesFormatBeforeUpdate(doc, field_names, modifier, options)

          self.setupDependentTasksUpdateHook()

          return

        destroyer: =>
          APP.justdo_project_pane.unregisterTab "justdo-dependencies"

          APP.modules.project_page.removePseudoCustomFields JustdoDependencies.dependencies_field_id
          APP.modules.project_page.removePseudoCustomFields JustdoDependencies.is_task_dates_frozen_pseudo_field_id

          self.unsetContextMenu()

          @collection_hook.remove()

          self.unsetDependentTasksUpdateHook()

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
            # XXX TY
            # if (grid_gantt = APP.justdo_grid_gantt)?
            #   grid_gantt.updateDependentTasks from_task_id
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
                # XXX TY
                # if (grid_gantt = APP.justdo_grid_gantt)?
                #   grid_gantt.updateTaskStartDateBasedOnDependencies JD.collections.Tasks.findOne to_task_id
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
          # XXX TY
          # if (grid_gantt = APP.justdo_grid_gantt)?
          #   dependent_obj = JD.collections.Tasks.findOne to_task_id
          #   grid_gantt.updateTaskStartDateBasedOnDependencies dependent_obj
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
              # XXX TY
              # if (grid_gantt = APP.justdo_grid_gantt)?
              #   grid_gantt.updateDependentTasks from_task_id
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

  setupContextMenu: ->
    self = @

    context_menu = APP.justdo_tasks_context_menu

    context_menu.registerMainSection "dependencies",
      position: 500
      data:
        label: "Depedencies"

    context_menu.registerSectionItem "dependencies", "freeze-dates",
      position: 100
      data:
        label: "Freeze start date and end date"
        op: (item_data, task_id, task_path, field_val, dependencies_fields_vals, field_info) ->
          APP.collections.Tasks.update task_id,
            $set:
              "#{JustdoDependencies.is_task_dates_frozen_pseudo_field_id}": "true"
          return
        icon_type: "feather"
        icon_val: "jd-rhombus"

      listingCondition: (item_definition, task_id, task_path, field_val, dependencies_fields_vals, field_info) ->
        return not self.isTaskDatesFrozen task_id
    
    context_menu.registerSectionItem "dependencies", "unfreeze-dates",
      position: 100
      data:
        label: "Unfreeze start date and end date"
        op: (item_data, task_id, task_path, field_val, dependencies_fields_vals, field_info) ->
          APP.collections.Tasks.update task_id,
            $set:
              "#{JustdoDependencies.is_task_dates_frozen_pseudo_field_id}": "false"
          return
        icon_type: "feather"
        icon_val: "jd-rhombus"

      listingCondition: (item_definition, task_id, task_path, field_val, dependencies_fields_vals, field_info) ->
        return self.isTaskDatesFrozen task_id
    
    return

  unsetContextMenu: ->
    context_menu = APP.justdo_tasks_context_menu
    context_menu.unregisterMainSection "dependencies"

    return
  
  isTaskDatesFrozen: (task_id) ->
    task = APP.collections.Tasks.findOne task_id,
      fields:
        "#{JustdoDependencies.is_task_dates_frozen_pseudo_field_id}": 1

    return task?[JustdoDependencies.is_task_dates_frozen_pseudo_field_id] == "true"

  _dependent_tasks_update_hook: null
  dependent_tasks_update_hook_enabled: true
  setupDependentTasksUpdateHook: ->
    self = @
    # on end date change or dependency added
    addNewIndependentAndRecalculateDates = (new_seq_id, doc) ->
      new_independnent_id = (APP.collections.Tasks.findOne
        project_id: doc.project_id
        seqId: new_seq_id
      ,
        fields: 
          _id: 1
      )?._id

      if new_independnent_id?
        preview = new TasksUpdatePreview()
        if not doc.justdo_task_dependencies_mf?
          doc.justdo_task_dependencies_mf = []
        doc.justdo_task_dependencies_mf.push
          type: "F2S"
          task_id: new_independnent_id
        self.updateTaskStartDateBasedOnDependencies doc, new_independnent_id, preview
        preview.updateDb()
      
      return

    self._dependent_tasks_update_hook = APP.collections.Tasks.before.update (user_id, doc, field_names, modifier, options) =>
      if not self.dependent_tasks_update_hook_enabled
        return 
      if (new_end_date = modifier?.$set?.end_date)? and new_end_date != doc.end_date
        preview = new TasksUpdatePreview()
        preview.update doc,
          end_date: new_end_date
        self.updateDependentTasks doc._id, preview
        preview.updateDb()
      else if doc[JustdoDependencies.is_task_dates_frozen_pseudo_field_id] != "true"
        if (new_seq_id = modifier?.$push?.justdo_task_dependencies)?
          addNewIndependentAndRecalculateDates new_seq_id, doc
        else if (new_seq_ids = modifier?.$set?.justdo_task_dependencies)?
          added_seq_ids = _.difference(new_seq_ids, doc.justdo_task_dependencies)
          for seq_id in added_seq_ids
            addNewIndependentAndRecalculateDates seq_id, doc
      
      return

    return
  
  unsetDependentTasksUpdateHook: ->
    @_dependent_tasks_update_hook.remove()

    return

  updateDependentTasks: (original_task_obj_id, preview) ->
    self = @

    JD.collections.Tasks.find
      "justdo_task_dependencies_mf.task_id": original_task_obj_id
      "#{JustdoDependencies.is_task_dates_frozen_pseudo_field_id}":
        $ne: "true"
    ,
      fields:
        justdo_task_dependencies_mf: 1
        start_date: 1
        end_date: 1
    .forEach (dependent) ->
      self.updateTaskStartDateBasedOnDependencies dependent, original_task_obj_id, preview
      return
    
    return
    
  updateTaskStartDateBasedOnDependencies: (dependent_obj, independent_id, preview) ->
    self = @
      # we need to now go over all independents tasks and find the limiting factors. This could have been done with a
      # single find command, but since it's a client side code, and we have the tasks' ids, it is easier to go one by
      # one. In this specific case, it's probably as effective.
      
      #todo: for now we just check F2S dependencies. When other types will be supported we will need to touch this code
    latest_independent_date = null
    if not (dependencies_mf = dependent_obj.justdo_task_dependencies_mf)?
      return
    for dependency in dependencies_mf
      independent_obj = preview.findOne dependency.task_id,
        "#{JustdoGridGantt.is_milestone_pseudo_field_id}": 1
        end_date: 1

      if dependency.type == "F2S"
        if (independent_end_date = independent_obj.end_date)?
          if not latest_independent_date? or independent_end_date > latest_independent_date
            latest_independent_date = independent_end_date
        if (latest_child = APP.justdo_grid_gantt.task_id_to_info[dependency.task_id]?.latest_child_end_time)?
          independent_end_date = moment.utc(latest_child).format("YYYY-MM-DD")
          if not latest_independent_date? or independent_end_date > latest_independent_date
            latest_independent_date = independent_end_date

    if latest_independent_date?
      if independent_obj[JustdoGridGantt.is_milestone_pseudo_field_id] == "true"
        new_start_date = moment.utc(latest_independent_date).format("YYYY-MM-DD")
      else 
        new_start_date = moment.utc(latest_independent_date).add(1, "day").format("YYYY-MM-DD")
      if new_start_date != dependent_obj.start_date
        # if independent_id? and self.task_ids_edited_locally.has independent_id
        #   self.task_ids_edited_locally.add dependent_obj._id
        self.moveTaskToNewStartDate dependent_obj, new_start_date, preview
    
    return
  
  moveTaskToNewStartDate: (task_obj, new_start_date, preview) ->
    self = @
    # Important note: in this version, we just use calendar days, we ignore weekends, holidays, vacations and personal days etc.
    # todo - include weekends and holidays in duration,
    # todo - don't start a task on weekend/holiday
    set_value = {}
    set_value.start_date = new_start_date
    task_duration = 1
    
    if (prev_start_date = task_obj.start_date)?
      if (prev_end_date = task_obj.end_date)?
        prev_start_date_moment = moment.utc prev_start_date
        prev_end_date_moment = moment.utc prev_end_date
        task_duration = prev_end_date_moment.diff prev_start_date_moment, "days"

    new_end_data_moment = moment.utc(new_start_date)
    new_end_data_moment = new_end_data_moment.add task_duration, "days"
    set_value.end_date = new_end_data_moment.format("YYYY-MM-DD")
    
    preview.update task_obj, set_value
    self.updateDependentTasks task_obj._id, preview

    return