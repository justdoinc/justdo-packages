_.extend JustdoTasksContextMenu.prototype,
  context_class: "grid-tree-control-context-menu"

  setupCoreMenuSections: ->
    self = @

    @registerMainSection "main",
      position: 100
    @registerSectionItem "main", "new-task",
      position: 100
      data:
        label: "New Task"
        op: (item_data, task_id, task_path, field_val, dependencies_fields_vals, field_info) ->
          APP.modules.project_page.performOp("addSiblingTask")

          return
        icon_type: "feather"
        icon_val: "plus"

      listingCondition: -> _.isEmpty(APP.modules.project_page.getUnfulfilledOpReq("addSiblingTask"))

    @registerSectionItem "main", "new-child-task",
      position: 200
      data:
        label: "New Child Task"
        op: (item_data, task_id, task_path, field_val, dependencies_fields_vals, field_info) ->
          APP.modules.project_page.performOp("addSubTask")

          return
        icon_type: "feather"
        icon_val: "corner-down-right"
    
    @registerSectionItem "main", "zoom-in",
      position: 300
      data:
        label: "Zoom in"
        op: (item_data, task_id, task_path, field_val, dependencies_fields_vals, field_info) ->
          APP.modules.project_page.performOp("zoomIn")

          return
        icon_type: "feather"
        icon_val: "zoom-in"

    getSubtreeItemsWithDifferentVals = (task_path, field_val, field_info) ->
      gc = APP.modules.project_page.gridControl()

      subtasks_with_different_val = {}
      gc._grid_data.each task_path, (section, item_type, item_obj) ->
        if item_obj._type?
          # Typed item, skip
          return
        
        if item_obj[field_info.field_name] != field_val
          subtasks_with_different_val[item_obj._id] = item_obj[field_info.field_name]
        return

      return subtasks_with_different_val

    @registerSectionItem "main", "apply-value-to-subtree",
      position: 400
      data:
        label: (item_data, task_id, task_path, field_val, dependencies_fields_vals, field_info) ->
          current_selected_value_label = field_info.column_field_schema?.grid_values?[field_val]?.txt

          return "Apply #{current_selected_value_label} to subtree"
        op: (item_data, task_id, task_path, field_val, dependencies_fields_vals, field_info) ->
          subtasks_with_different_val = getSubtreeItemsWithDifferentVals(task_path, field_val, field_info)

          if _.isEmpty(subtasks_with_different_val)
            return

          for task_id, task_val of subtasks_with_different_val
            APP.collections.Tasks.update task_id,
              $set:
                "#{field_info.field_name}": field_val

          current_selected_value_label = field_info.column_field_schema?.grid_values?[field_val]?.txt

          JustdoSnackbar.show
            text: "#{_.size(subtasks_with_different_val)} subtree tasks set as #{current_selected_value_label}."
            actionText: "Dismiss"
            showSecondButton: true
            secondButtonText: "Undo"
            duration: 10000
            onActionClick: =>
              JustdoSnackbar.close()
              return

            onSecondButtonClick: =>
              for task_id, task_val of subtasks_with_different_val
                APP.collections.Tasks.update task_id,
                  $set:
                    "#{field_info.field_name}": task_val
              JustdoSnackbar.close()
              return


          return
        icon_type: "feather"
        icon_val: "arrow-down-right"

      listingCondition: (item_definition, task_id, task_path, field_val, dependencies_fields_vals, field_info) ->
        if not field_info?
          # Happens when initiating the context menu
          return false
        
        if field_info.formatter_name != "keyValueFormatter"
          return false

        # Ensure there are *visible* children (when all children are hidden filterAwareGetPathHasChildren returns == 2),
        # IMPORTANT we do apply the value to items that didn't pass the filter as well, it is just going to be weird
        # product wise to show the option to apply the value to children when it isn't clear there are children.
        if not (gc = APP.modules.project_page.gridControl())?
          return false
        
        if gc._grid_data.filterAwareGetPathHasChildren(task_path) != 1
          return false

        return true

    @registerSectionItem "main", "reorder-children",
      position: 500
      data:
        label: "Reorder children by"
        is_nested_section: true
        icon_type: "feather"
        icon_val: "jd-sort"

      listingCondition: ->
        if not (gc = APP.modules.project_page?.gridControl())?
          return false
        return _.isEmpty(gc.sortActivePathByPriorityDesc.prereq())

    @registerNestedSection "main", "reorder-children", "reorder-children-items",
      position: 100

    supported_reorderings = [
      {
        field_id: "priority"
        label: "Priority"
        order: -1 # -1 for DESC 1 for ASC
      }
      {
        field_id: "title"
        label: "Subject"
        order: 1 # -1 for DESC 1 for ASC
      }
    ]

    current_position = 100
    for supported_reordering in supported_reorderings
      do (supported_reordering) =>
        {field_id, label, order} = supported_reordering

        @registerSectionItem "reorder-children-items", "reorder-children-by-#{field_id}",
          position: current_position
          data:
            label: label
            op: (item_data, task_id, task_path, field_val, dependencies_fields_vals, field_info) ->
              if not (gc = APP.modules.project_page?.gridControl())?
                return false
              gc._grid_data.sortChildren task_path, field_id, order
              return
            icon_type: "none"
            
        return

      current_position += 100

    @registerMainSection "copy-paste",
      position: 200

    @registerSectionItem "copy-paste", "copy",
      position: 100
      data:
        label: "Copy"
        op: (item_data, task_id, task_path, field_val, dependencies_fields_vals, field_info) ->
          clipboard.copy
            "text/plain": field_val or ""
          return
        icon_type: "feather"
        icon_val: "copy"

    @registerSectionItem "copy-paste", "paste",
      position: 200
      data:
        label: "Paste"
        op: (item_data, task_id, task_path, field_val, dependencies_fields_vals, field_info) ->
          # Credit: https://stackoverflow.com/questions/6413036/get-current-clipboard-content
          navigator.clipboard.readText()
            .then (text) =>
              if (allowed_grid_values = field_info?.column_field_schema?.grid_values)? and
                  text not of allowed_grid_values
                console.warn "Value '#{text}' isn't allowed."

                return

              APP.collections.Tasks.update task_id,
                $set:
                  "#{field_info.field_name}": text

              return
            .catch (err) =>
              console.error("Failed to read clipboard contents: ", err)

          # Another approach that we might use in the future:
          #
          # navigator.clipboard.read()
          #   .then (clipboard_items) =>
          #     for clipboard_item in clipboard_items
          #       for type in clipboard_item.types
          #         clipboard_item.getType(type)
          #           .then (blob) =>
          #             console.log(blob)

          return
        icon_type: "feather"
        icon_val: "clipboard"
      listingCondition: (item_definition, task_id, task_path, field_val, dependencies_fields_vals, field_info) ->
        if not field_info?.column_field_schema?.grid_editable_column
          return false

        if not (field_id = field_info?.field_name)?
          return false

        # If tasks locks are installed, and if so, whether the task is locked and if so, whether the current field_id is
        # restricted when the task is locked
        if APP.custom_justdo_tasks_locks.isPluginInstalledOnProjectDoc(JD.activeJustdo())
          if not APP.custom_justdo_tasks_locks.isActiveUserAllowedToPerformRestrictedOperationsOnActiveTask()
            if field_id in CustomJustdoTasksLocks.restricted_fields
              return false

        return true

    @registerMainSection "projects",
      position: 300
      data:
        label: "Projects"
      listingCondition: ->
        if not (cur_proj = APP.modules.project_page.curProj())?
          return true 
        return cur_proj.isCustomFeatureEnabled(JustdoDeliveryPlanner.project_custom_feature_id)
    
    @registerSectionItem "projects", "set-as-a-project",
      position: 100
      data:
        label: "Set as a Project"
        op: (item_data, task_id, task_path, field_val, dependencies_fields_vals, field_info) ->
          APP.justdo_delivery_planner.toggleTaskIsProject task_id
          return 
        icon_type: "feather"
        icon_val: "folder"
      listingCondition: (item_definition, task_id, task_path, field_val, dependencies_fields_vals, field_info) ->
        return dependencies_fields_vals?["p:dp:is_project"] != true
    
    @registerSectionItem "projects", "unset-as-a-project",
      position: 200
      data:
        label: "Unset as a Project"
        op: (item_data, task_id, task_path, field_val, dependencies_fields_vals, field_info) ->
          APP.justdo_delivery_planner.toggleTaskIsProject task_id
          return
        icon_type: "feather"
        icon_val: "folder-minus"
      listingCondition: (item_definition, task_id, task_path, field_val, dependencies_fields_vals, field_info) ->
        return dependencies_fields_vals?["p:dp:is_project"] is true

    @registerSectionItem "projects", "open-close-project",
      position: 300
      data:
        label: (item_data, task_id, task_path, field_val, dependencies_fields_vals, field_info) ->
          if dependencies_fields_vals?["p:dp:is_archived_project"]
            return "Reopen Project"
          else
            return "Close Project"
        op: (item_data, task_id, task_path, field_val, dependencies_fields_vals, field_info) ->
          APP.justdo_delivery_planner.toggleTaskArchivedProjectState task_id
          return 
        icon_type: "feather"
        icon_val: "folder"
      listingCondition: (item_definition, task_id, task_path, field_val, dependencies_fields_vals, field_info) ->
        return dependencies_fields_vals?["p:dp:is_project"] is true
    
    # @registerSectionItem "projects", "assign-to-project",
    #   position: 300
    #   data:
    #     label: "Assign to Project"
    #     is_nested_section: true
    #     icon_type: "feather"
    #     icon_val: "corner-right-down"
    
    # @registerNestedSection "projects", "assign-to-project", "assign-to-project-items",
    #   position: 100

    # @_getTaskAvailableAssignProjectList = =>
    #   if not current_project_id = APP.modules.project_page.curProj()?.id
    #     return

    #   if not (active_item_obj = APP.modules.project_page.activeItemObj())?
    #     return

    #   exclude_tasks = [active_item_obj._id].concat(_.keys active_item_obj.parents)

    #   project_tasks = APP.justdo_delivery_planner.getKnownProjects(current_project_id, {active_only: true, exclude_tasks: exclude_tasks}, Meteor.userId())

    #   gc = APP.modules.project_page.mainGridControl()

    #   grid_data = gc?._grid_data

    #   # Remove projects that are tasks to which we can't be assigned as a child due to circular
    #   # chain.
    #   project_tasks = _.filter project_tasks, (task) ->
    #     for task_path in grid_data.getAllCollectionItemIdPaths(task._id)
    #       reg = new RegExp("/#{active_item_obj._id}/")

    #       if reg.test(task_path)
    #         return false

    #     return true

    #   return project_tasks
    
    # @_addNewParentToActiveItemId = (new_parent_id, cb) ->
    #   module = APP.modules.project_page
    #   gc = module.gridControl()
    #   grid_data = gc?._grid_data

    #   if grid_data?
    #     gc?.saveAndExitActiveEditor() # Exit edit mode, if any, to make sure result will appear on tree (otherwise, will show only when exit edit mode)

    #     current_item_id = module.activeItemId()

    #     gc._performLockingOperation (releaseOpsLock, timedout) =>
    #       gc.addParent current_item_id, {parent: new_parent_id, order: 0}, (err) ->
    #         releaseOpsLock()

    #         cb?(err)
    #   else
    #     APP.logger.error "Context: couldn't retrieve grid_data object"

    #   return

    # project_items_to_unregister = []
    # Tracker.autorun =>
    #   for item in project_items_to_unregister
    #     @unregisterSectionItem "assign-to-project-items", item
    #   project_items_to_unregister = []
      
    #   if (projects_list = @_getTaskAvailableAssignProjectList())?
    #     i = 1
    #     for project in projects_list
    #       @registerSectionItem "assign-to-project-items", project._id,
    #         position: i * 100
    #         data:
    #           label: "##{project.seqId} #{if project.title? then project.title else ""}"
    #           op: ->
    #             self._addNewParentToActiveItemId project._id, (err) ->
    #               if err?
    #                 console.log err
    #               return
    #             return
    #       project_items_to_unregister.push project._id
    #       i = i + 1

    #     if i == 1
    #       @registerSectionItem "assign-to-project-items", "no-projects-available",
    #         position: 100
    #         data:
    #           label: "No projects available for assigning."
    #           op: -> return
    #       project_items_to_unregister.push "no-projects-available"

    #   return

    return