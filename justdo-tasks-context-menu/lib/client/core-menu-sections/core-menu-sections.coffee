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

      listingCondition: ->
        unfulfilled_op_req = APP.modules.project_page.getUnfulfilledOpReq("addSiblingTask")

        delete unfulfilled_op_req.ops_locked # We ignore that lock to avoid flickering when locking ops are performed from the contextmenu

        return _.isEmpty(unfulfilled_op_req)

    @registerSectionItem "main", "new-child-task",
      position: 200
      data:
        label: "New Child Task"
        op: (item_data, task_id, task_path, field_val, dependencies_fields_vals, field_info) ->
          APP.modules.project_page.performOp("addSubTask")

          return
        icon_type: "feather"
        icon_val: "corner-down-right"

      listingCondition: ->
        unfulfilled_op_req = APP.modules.project_page.getUnfulfilledOpReq("addSubTask")

        delete unfulfilled_op_req.ops_locked # We ignore that lock to avoid flickering when locking ops are performed from the contextmenu

        return _.isEmpty(unfulfilled_op_req)

    @registerSectionItem "main", "add-to-favorites",
      position: 250
      data:
        label: (item_data, task_id, task_path, field_val, dependencies_fields_vals, field_info) ->
          if not (task_doc = APP.collections.Tasks.findOne(task_id, {fields: {_id: 1, "priv:favorite": 1}}))?
            # This should never happen
            return ""

          if task_doc["priv:favorite"]?
            return "Remove from favorites"
          else
            return "Add to favorites"
        op: (item_data, task_id, task_path, field_val, dependencies_fields_vals, field_info) ->
          if not (task_doc = APP.collections.Tasks.findOne(task_id, {fields: {_id: 1, "priv:favorite": 1}}))?
            # This should never happen
            return

          if task_doc["priv:favorite"]?
            APP.modules.project_page.performOp("removeFromFavorites")
          else
            APP.modules.project_page.performOp("addToFavorites")

          return
        icon_type: "feather"
        icon_val: "star"

      listingCondition: (item_definition, task_id, task_path, field_val, dependencies_fields_vals, field_info) ->
        if not (task_doc = APP.collections.Tasks.findOne(task_id, {fields: {_id: 1, "priv:favorite": 1}}))?
          # This should never happen
          return

        if task_doc["priv:favorite"]?
          unfulfilled_op_req = APP.modules.project_page.getUnfulfilledOpReq("removeFromFavorites")
        else
          unfulfilled_op_req = APP.modules.project_page.getUnfulfilledOpReq("addToFavorites")

        delete unfulfilled_op_req.ops_locked # We ignore that lock to avoid flickering when locking ops are performed from the contextmenu

        return _.isEmpty(unfulfilled_op_req)

    @registerSectionItem "main", "remove-task",
      position: 300
      data:
        label: "Remove Task"
        op: (item_data, task_id, task_path, field_val, dependencies_fields_vals, field_info) ->
          APP.modules.project_page.performOp("removeTask")

          return
        icon_type: "feather"
        icon_val: "trash"

      listingCondition: ->
        unfulfilled_op_req = APP.modules.project_page.getUnfulfilledOpReq("removeTask")

        delete unfulfilled_op_req.ops_locked # We ignore that lock to avoid flickering when locking ops are performed from the contextmenu

        return _.isEmpty(unfulfilled_op_req)

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
          current_selected_value_label = field_info.column_field_schema?.grid_values?[field_val]?.txt or "value"

          return "Apply #{current_selected_value_label} to subtree"
        op: (item_data, task_id, task_path, field_val, dependencies_fields_vals, field_info) ->
          subtasks_with_different_val = getSubtreeItemsWithDifferentVals(task_path, field_val, field_info)

          if _.isEmpty(subtasks_with_different_val)
            return

          if field_val is undefined
            field_val = null

          for task_id, task_val of subtasks_with_different_val
            APP.collections.Tasks.update task_id,
              $set:
                "#{field_info.field_name}": field_val

          current_selected_value_label = field_info.column_field_schema?.grid_values?[field_val]?.txt or "value"

          JustdoSnackbar.show
            text: "#{_.size(subtasks_with_different_val)} subtree tasks set as #{current_selected_value_label}."
            showDismissButton: true
            actionText: "Undo"
            duration: 10000
            onActionClick: =>
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

        unfulfilled_op_req = gc.sortActivePathByPriorityDesc.prereq()

        delete unfulfilled_op_req.ops_locked # We ignore that lock to avoid flickering when locking ops are performed from the contextmenu

        return _.isEmpty(unfulfilled_op_req)

    @registerNestedSection "main", "reorder-children", "reorder-children-items",
      position: 100

    getLabelForFieldId = (field_id) ->
      return JustdoHelpers.getCollectionSchemaForField(APP.collections.Tasks, field_id)?.label or field_id

    supported_reorderings = [
      {
        field_id: "priority"
        # label: "Priority #{Math.random()}" # <- YOU ARE ALLOWED TO SET CUSTOM LABEL
        order: -1 # -1 for DESC 1 for ASC
      }
      {
        field_id: "title"
        # label: "Subject"
        order: 1 # -1 for DESC 1 for ASC
      }
      {
        field_id: "start_date"
        # label: "Start Date"
        order: 1 # -1 for DESC 1 for ASC
      }
      {
        field_id: "end_date"
        # label: "End Date"
        order: 1 # -1 for DESC 1 for ASC
      }
      {
        field_id: "due_date"
        # label: "Due Date"
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
            label: -> if label then label else getLabelForFieldId(field_id)
            op: (item_data, task_id, task_path, field_val, dependencies_fields_vals, field_info) ->
              if not (gc = APP.modules.project_page?.gridControl())?
                return false
              gc._grid_data.sortChildren task_path, field_id, order
              return
            icon_type: "none"
            
        return

      current_position += 100

    @registerMainSection "zoom-in",
      position: 200

    @registerSectionItem "zoom-in", "zoom-in",
      position: 100
      data:
        label: "Zoom in"
        op: (item_data, task_id, task_path, field_val, dependencies_fields_vals, field_info) ->
          APP.modules.project_page.performOp("zoomIn")

          return
        icon_type: "feather"
        icon_val: "zoom-in"

    # @registerMainSection "copy-paste",
    #   position: 300

    # @registerSectionItem "copy-paste", "copy",
    #   position: 100
    #   data:
    #     label: "Copy"
    #     op: (item_data, task_id, task_path, field_val, dependencies_fields_vals, field_info) ->
    #       clipboard.copy
    #         "text/plain": field_val or ""
    #       return
    #     icon_type: "feather"
    #     icon_val: "copy"

    # isFieldEditable = (item_definition, task_id, task_path, field_val, dependencies_fields_vals, field_info) ->
    #   if not field_info?.column_field_schema?.grid_editable_column
    #     return false

    #   if not (field_id = field_info?.field_name)?
    #     return false

    #   # If tasks locks are installed, and if so, whether the task is locked and if so, whether the current field_id is
    #   # restricted when the task is locked
    #   if APP.custom_justdo_tasks_locks.isPluginInstalledOnProjectDoc(JD.activeJustdo({conf: 1}))
    #     if not APP.custom_justdo_tasks_locks.isActiveUserAllowedToPerformRestrictedOperationsOnActiveTask()
    #       if field_id in CustomJustdoTasksLocks.restricted_fields
    #         return false

    #   return true

    # @registerSectionItem "copy-paste", "paste",
    #   position: 200
    #   data:
    #     label: "Paste"
    #     op: (item_data, task_id, task_path, field_val, dependencies_fields_vals, field_info) ->
    #       # Credit: https://stackoverflow.com/questions/6413036/get-current-clipboard-content
    #       navigator.clipboard.readText()
    #         .then (text) =>
    #           if (allowed_grid_values = field_info?.column_field_schema?.grid_values)? and
    #               text not of allowed_grid_values
    #             console.warn "Value '#{text}' isn't allowed."

    #             return

    #           APP.collections.Tasks.update task_id,
    #             $set:
    #               "#{field_info.field_name}": text

    #           return
    #         .catch (err) =>
    #           console.error("Failed to read clipboard contents: ", err)

    #       # Another approach that we might use in the future:
    #       #
    #       # navigator.clipboard.read()
    #       #   .then (clipboard_items) =>
    #       #     for clipboard_item in clipboard_items
    #       #       for type in clipboard_item.types
    #       #         clipboard_item.getType(type)
    #       #           .then (blob) =>
    #       #             console.log(blob)

    #       return
    #     icon_type: "feather"
    #     icon_val: "clipboard"
    #   listingCondition: isFieldEditable

    # @registerSectionItem "copy-paste", "clear",
    #   position: 300
    #   data:
    #     label: "Clear"
    #     op: (item_data, task_id, task_path, field_val, dependencies_fields_vals, field_info) ->
    #       value_to_set = null

    #       if field_info.field_name == "state"
    #         value_to_set = "nil"

    #       APP.collections.Tasks.update task_id,
    #         $set:
    #           "#{field_info.field_name}": value_to_set

    #       JustdoSnackbar.show
    #         text: "#{field_info.column_field_schema.label} cleared"
    #         showSecondButton: true
    #         secondButtonText: "Undo"
    #         duration: 7000
    #         showDismissButton: true
    #         onSecondButtonClick: =>
    #           APP.collections.Tasks.update task_id,
    #             $set:
    #               "#{field_info.field_name}": field_val

    #           JustdoSnackbar.close()

    #           return

    #       return
    #     icon_type: "feather"
    #     icon_val: "x-square"
    #   listingCondition: isFieldEditable

    do () => # Do, to emphesize that it can move out of the core-menu-sections.coffee file
      self = @
      self.registerMainSection "projects",
        position: 400
        data:
          label: "Projects"
        listingCondition: ->
          # if not (cur_proj = APP.modules.project_page.curProj())?
          #   return true 
          # return cur_proj.isCustomFeatureEnabled(JustdoDeliveryPlanner.project_custom_feature_id)
          return true # In Jul 2nd 2020 projects became a built-in feature

      self.registerSectionItem "projects", "set-as-a-project",
        position: 200
        data:
          label: (item_data, task_id, task_path, field_val, dependencies_fields_vals, field_info) ->
            if task_id? and APP.justdo_delivery_planner.isTaskObjProject(APP.collections.Tasks.findOne(task_id, {fields: {_id: 1, "#{JustdoDeliveryPlanner.task_is_project_field_name}": 1}}))
              return "Unset as a Project"
            return "Set as a Project"
          op: (item_data, task_id, task_path, field_val, dependencies_fields_vals, field_info) ->
            APP.justdo_delivery_planner.toggleTaskIsProject task_id
            return 
          icon_type: "feather"
          icon_val: (item_data, task_id, task_path, field_val, dependencies_fields_vals, field_info) ->
            if task_id? and APP.justdo_delivery_planner.isTaskObjProject(APP.collections.Tasks.findOne(task_id, {fields: {_id: 1, "#{JustdoDeliveryPlanner.task_is_project_field_name}": 1}}))
              return "folder-minus"
            return "folder"
        listingCondition: (item_definition, task_id, task_path, field_val, dependencies_fields_vals, field_info) ->
          return true
      
      self.registerSectionItem "projects", "open-close-project",
        position: 300
        data:
          label: (item_data, task_id, task_path, field_val, dependencies_fields_vals, field_info) ->
            if dependencies_fields_vals?[JustdoDeliveryPlanner.task_is_archived_project_field_name]
              return "Reopen Project"
            else
              return "Close Project"
          op: (item_data, task_id, task_path, field_val, dependencies_fields_vals, field_info) ->
            APP.justdo_delivery_planner.toggleTaskArchivedProjectState task_id
            return 
          icon_type: "feather"
          icon_val: "folder"
        listingCondition: (item_definition, task_id, task_path, field_val, dependencies_fields_vals, field_info) ->
          return dependencies_fields_vals?[JustdoDeliveryPlanner.task_is_project_field_name] is true
      
      self.registerSectionItem "projects", "manage-projects",
        position: 100
        data:
          label: "Add to project"
          is_nested_section: true
          icon_type: "feather"
          icon_val: "corner-right-down"

        listingCondition: ->
          # Don't present manage projects if there are no tasks set as projects yet
          if not (current_justdo_id = JD.activeJustdo({_id: 1})?._id)?
            return

          query =
            project_id: current_justdo_id
            "#{JustdoDeliveryPlanner.task_is_project_field_name}": true

          options =
            fields:
              _id: 1
              "#{JustdoDeliveryPlanner.task_is_project_field_name}": 1

          return APP.collections.Tasks.findOne(query, options)?

      getAllJustdoActiveProjectsSortedByProjectName = (filter_state) ->
        options = 
          active_only: true
          sort_by: {seqId: -1}

        if not _.isEmpty(filter_state)
          options.customize_query =
            title:
              $regex: new RegExp(JustdoHelpers.escapeRegExp(filter_state), "i")

        project_tasks = APP.justdo_delivery_planner.getKnownProjects(JD.activeJustdo({_id: 1})?._id, options, Meteor.userId())

        return APP.justdo_delivery_planner.excludeProjectsCauseCircularChain project_tasks, JD.activeItemId()
        
      addNewParentToTaskId = (task_id, new_parent_id, cb) ->
        module = APP.modules.project_page
        gc = module.gridControl()
        
        gc.saveAndExitActiveEditor() # Exit edit mode, if any, to make sure result will appear on tree (otherwise, will show only when exit edit mode)

        gc._performLockingOperation (releaseOpsLock, timedout) =>
          gc.addParent task_id, {parent: new_parent_id, order: 0}, (err) ->
            releaseOpsLock()

            cb?(err)

            return

          return

        return

      removeParent = (item_path, cb) ->
        module = APP.modules.project_page
        gc = module.gridControl()
        
        gc._performLockingOperation (releaseOpsLock, timedout) =>
          gc._grid_data?.removeParent item_path, (err) =>
            releaseOpsLock()

            if err?
              APP.logger.error "Error: #{err}"

            return

          return

        return

      self.registerNestedSection "projects", "manage-projects", "manage-active-projects",
        position: 100

        data:
          display_item_filter_ui: true

          itemsGenerator: ->
            res = []

            active_projects_docs = getAllJustdoActiveProjectsSortedByProjectName(self.getSectionFilterState("manage-active-projects"))

            active_item_id = JD.activeItemId()

            if _.isEmpty(_.filter(active_projects_docs, (active_project_doc) -> active_project_doc._id != active_item_id)) # Show only if there are no other projects (filter myself out, in case I am a project)
              res.push
                label: "No projects are available"
                op: -> return
                icon_type: "none"

            for project_task_doc, i in active_projects_docs
              do (project_task_doc, i) ->
                if project_task_doc._id != active_item_id # Don't show current task
                  res.push
                    id: project_task_doc._id

                    label: -> return JustdoHelpers.ellipsis(project_task_doc.title or "", 40)
                    label_addendum_template: "manage_active_projects_jump_to_proj"
                    op: (item_data, task_id, task_path, field_val, dependencies_fields_vals, field_info) ->
                      query =
                        _id: task_id
                        "parents.#{project_task_doc._id}": {$exists: true}

                      options =
                        fields:
                          _id: 1
                          parents: 1

                      if (task_doc = APP.collections.Tasks.findOne(query, options))?
                        performRemoveParent = ->
                          removeParent "/#{project_task_doc._id}/#{task_id}/", (err) ->
                            if err?
                              console.error err
                            return
                        if _.size(task_doc.parents) > 1
                          performRemoveParent()
                        else
                          JustdoSnackbar.show
                            text: "This is the last parent of the task, do you want to remove the task completely?"
                            showDismissButton: true
                            actionText: "Remove"
                            duration: 10000
                            onActionClick: =>
                              performRemoveParent()
                              JustdoSnackbar.close()
                              return
                      else
                        addNewParentToTaskId task_id, project_task_doc._id, (err) ->
                          if err?
                            console.error err
                          return

                      return
                    icon_type: "feather"
                    icon_val: (item_data, task_id, task_path, field_val, dependencies_fields_vals, field_info) ->
                      if not task_id?
                        return

                      query =
                        _id: task_id

                      options =
                        fields:
                          _id: 1
                          parents: 1

                      task_doc = APP.collections.Tasks.findOne(query, options) # We could have used gc._grid_data.items_by_id[task_id].parents, but we need reativity anyways

                      if project_task_doc._id of task_doc.parents
                        return "check-square"
                      return "square"

                    close_on_click: false

            return res

