MAX_ALLOWED_SUBTREE_REMOVAL_TASKS = 50 # Excluding the sub-tree root

_.extend JustdoTasksContextMenu.prototype,
  context_class: "grid-tree-control-context-menu"

  setupCoreMenuSections: ->
    self = @

    @registerMainSection "main",
      position: 100

    @registerSectionItem "main", "new-task",
      position: 100
      data:
        label: "New Sibling Task"
        label_i18n: "new_sibling_task_label"
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
        label_i18n: "new_child_task_label"
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
        label_i18n: (item_data, task_id, task_path, field_val, dependencies_fields_vals, field_info) ->
          if not (task_doc = APP.collections.Tasks.findOne(task_id, {fields: {_id: 1, "priv:favorite": 1}}))?
            # This should never happen
            return ""

          if task_doc["priv:favorite"]?
            return "remove_from_favorites_label"
          else
            return "add_to_favorites_label"

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
        if not (gc = APP.modules.project_page?.gridControl())?
          return false

        if gc.isMultiSelectMode()
          return false

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
        label: ->
          if not (gc = APP.modules.project_page?.gridControl())?
            return false

          if gc.isMultiSelectMode()
            return "Remove Tasks"

          if Object.keys(JD.activeItem({parents: 1}).parents).length > 1
            return "Remove From Parent"

          return "Remove Task"

        label_i18n: ->
          if not (gc = APP.modules.project_page?.gridControl())?
            return false

          if gc.isMultiSelectMode()
            return "remove_tasks_label"

          if Object.keys(JD.activeItem({parents: 1}).parents).length > 1
            return "remove_from_parent_label"

          return "remove_task_label"

        op: (item_data, task_id, task_path, field_val, dependencies_fields_vals, field_info) ->
          APP.modules.project_page.performOp("removeTask")

          return
        icon_type: "feather"
        icon_val: "trash"

      listingCondition: ->
        unfulfilled_op_req = APP.modules.project_page.getUnfulfilledOpReq("removeTask")

        delete unfulfilled_op_req.ops_locked # We ignore that lock to avoid flickering when locking ops are performed from the contextmenu

        return _.isEmpty(unfulfilled_op_req)
    
    @registerSectionItem "main", "remove-subtree",
      position: 400
      data:
        label: "Remove with Sub-Tree"
        label_i18n: "remove_with_subtree_label"

        op: (item_data, task_id, task_path, field_val, dependencies_fields_vals, field_info) ->
          task = APP.collections.Tasks.findOne(task_id, {fields: {seqId: 1, title: 1}})
          bootbox.confirm "Are you sure you want to remove the task and its entire sub-tree of #{JustdoHelpers.taskCommonName(task)}?", (result) ->
            if result
              if (gd = APP.modules.project_page.gridData())?
                paths = [task_path]

                gd.each(JD.activePath(), {}, (section, item_type, item_obj, path, expand_state) ->
                  paths.push path
                  return
                )

                gd.removeParent paths, (err) ->
                  if err?
                    JustdoSnackbar.show
                      text: "Cannot remove sub-tree because some tasks have multi-parents."
                      duration: 5000

                  return
            return
          return
        icon_type: "feather"
        icon_val: "trash"

      listingCondition: ->
        if not (gc = APP.modules.project_page?.gridControl())?
          return false

        if gc.isMultiSelectMode()
          return false

        # Ensure that we have a green-light to remove the active task before checking whether
        # we allow to remove its sub-tree
        unfulfilled_op_req = gc.removeActivePath.prereq()
        delete unfulfilled_op_req.ops_locked # We ignore that lock to avoid flickering when locking ops are performed from the contextmenu
        delete unfulfilled_op_req.active_path_is_not_leaf # This cause is issue only for the regurlar remove operation and not for the remove-subtree

        if not _.isEmpty(unfulfilled_op_req)
          return false

        counter = 0
        condition_is_satisfied = true
        APP.modules.project_page.gridData().each(JD.activePath(), {}, (section, item_type, item_obj, path, expand_state) ->
          if Object.keys(item_obj.parents).length > 1
            condition_is_satisfied = false
            console.info "Remove subtree prevented: a task with more than one parent found #{item_obj._id}"

            return -2

          if counter == MAX_ALLOWED_SUBTREE_REMOVAL_TASKS
            condition_is_satisfied = false
            console.info "Remove subtree prevented: more than #{MAX_ALLOWED_SUBTREE_REMOVAL_TASKS} tasks in sub-tree"

            return -2

          counter += 1

          return
        )
        
        if counter == 0
          return false
          
        return condition_is_satisfied

    @registerSectionItem "main", "archive-unarchive-task",
      position: 500
      data:
        label: ->
          task_archived = JD.activeItem({archived: 1}).archived

          if _.isDate task_archived
            return "Unarchive Task"

          return "Archive Task"
        label_i18n: ->
          task_archived = JD.activeItem({archived: 1}).archived

          if _.isDate task_archived
            return "unarchive_task_label"

          return "archive_task_label"

        op: (item_data, task_id, task_path, field_val, dependencies_fields_vals, field_info) ->
          op =
            $set:
              archived: new Date()
          changelog_msg = "archived the task"

          task_archived = APP.collections.Tasks.findOne(task_id, {fields: {archived: 1}}).archived

          if _.isDate task_archived
            op.$set.archived = null
            changelog_msg = "unarchived the task"

          APP.collections.Tasks.update task_id, op
          return

        icon_type: "feather"
        icon_val: "archive"

      listingCondition: (item_definition, task_id, task_path, field_val, dependencies_fields_vals, field_info) ->
        if not (gc = APP.modules.project_page?.gridControl())?
          return false

        if gc.isMultiSelectMode()
          return false

        return APP.justdo_permissions.checkTaskPermissions("task-field-edit.archived", task_id)

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
        label_i18n: (item_data, task_id, task_path, field_val, dependencies_fields_vals, field_info) ->
          current_selected_value = field_info.column_field_schema?.grid_values?[field_val]
          current_selected_value_label = current_selected_value?.txt
          current_selected_value_i18n = current_selected_value?.txt_i18n

          translated_value_label = APP.justdo_i18n.getDefaultI18nTextOrCustomInput {i18n_key: current_selected_value_i18n, text: current_selected_value_label}

          return {label_i18n: "apply_value_to_subtree", options_i18n: {value: translated_value_label}}
          
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
        label_i18n: "reorder_children_by_label"
        is_nested_section: true
        icon_type: "feather"
        icon_val: "jd-sort"

      listingCondition: ->
        if not (gc = APP.modules.project_page?.gridControl())?
          return false

        if gc.isMultiSelectMode()
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
      {
        field_id: "follow_up"
        # label: "Follow Up"
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
            label_i18n: "#{field_id}_schema_label"
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
      hide_border: true
      listingCondition: ->
        if not (gc = APP.modules.project_page?.gridControl())?
          return false

        if gc.isMultiSelectMode()
          return false

        return true

    @registerSectionItem "zoom-in", "zoom-in",
      position: 100
      data:
        label: "Zoom in"
        label_i18n: "zoom_in_label"
        op: (item_data, task_id, task_path, field_val, dependencies_fields_vals, field_info) ->
          APP.modules.project_page.performOp("zoomIn")

          return
        icon_type: "feather"
        icon_val: "zoom-in"

    bulk_set_options_fields = []
    behavior_by_editor_type = 
      SelectorEditor:
        close_on_click: true
        op: (item_data, task_id, task_path, field_val, dependencies_fields_vals, field_info) ->
          gc = APP.modules.project_page?.gridControl()
          field_id = item_data.field_id
          field_val = item_data.id
          selected_task_ids = _.map gc.getFilterPassingMultiSelectedPathsArray(), (path) -> GridData.helpers.getPathItemId path
          for task_id in selected_task_ids
            APP.collections.Tasks.update task_id, {$set: {[field_id]: field_val}}
          return
      MultiSelectEditor:
        close_on_click: false
        op: (item_data, task_id, task_path, field_val, dependencies_fields_vals, field_info) ->
          gc = APP.modules.project_page?.gridControl()
          field_id = item_data.field_id
          field_val = item_data.id
          selected_task_ids = _.map gc.getFilterPassingMultiSelectedPathsArray(), (path) -> GridData.helpers.getPathItemId path

          is_all_tasks_has_this_value = true
          APP.collections.Tasks.find({_id: {$in: selected_task_ids}}, {fields: {[field_id]: 1}}).forEach (task) ->
            is_this_task_has_this_value = _.contains task[field_id], field_val
            is_all_tasks_has_this_value = is_all_tasks_has_this_value and is_this_task_has_this_value
            return
          
          if is_all_tasks_has_this_value
            op = 
              $pull:
                [field_id]: field_val
          else
            op = 
              $addToSet:
                [field_id]: field_val

          for task_id in selected_task_ids
            APP.collections.Tasks.update task_id, op
          
          return
        icon_type: "feather"
        icon_class: ""
        icon_val: (item_data, task_id, task_path, field_val, dependencies_fields_vals, field_info) ->
          gc = APP.modules.project_page?.gridControl()
          field_id = item_data.field_id
          field_val = item_data.id
          selected_task_ids = _.map gc.getFilterPassingMultiSelectedPathsArray(), (path) -> GridData.helpers.getPathItemId path

          is_all_tasks_has_this_value = true
          is_some_tasks_has_this_value = false
          APP.collections.Tasks.find({_id: {$in: selected_task_ids}}, {fields: {[field_id]: 1}}).forEach (task) ->
            is_this_task_has_this_value = _.contains task[field_id], field_val
            is_all_tasks_has_this_value = is_all_tasks_has_this_value and is_this_task_has_this_value
            is_some_tasks_has_this_value = is_some_tasks_has_this_value or is_this_task_has_this_value
            return

          if is_all_tasks_has_this_value
            return "check-square"
          
          if is_some_tasks_has_this_value
            return "minus-square"

          return "square"
    @registerMainSection "bulk-set-options",
      position: 150
      data:
        label: "Set"
        label_i18n: "bulk_set_options_label"
        display_item_filter_ui: true
        limit_rendered_items: true
        limit_rendered_items_initial_items: 5
        limit_rendered_items_load_more_items: 10
        itemsGenerator: ->
          bulk_set_options_fields = []
          ret = []
          if not (gc = APP.modules.project_page?.gridControl())?
            return ret
          
          for field_id, field_def of gc.getSchemaExtendedWithCustomFields()
            do (field_id, field_def) ->
              if (field_def.grid_column_editor in ["SelectorEditor", "MultiSelectEditor"]) and (field_def.exclude_from_context_menu_bulk_set isnt true) and field_def.grid_editable_column
                bulk_set_options_fields.push field_id
                editor_specific_behavior = behavior_by_editor_type[field_def.grid_column_editor]
                ret.push
                  id: "bulk-set-options-#{field_id}"
                  close_on_click: editor_specific_behavior.close_on_click
                  label: field_def.label
                  label_i18n: field_def.label_i18n
                  is_nested_section: true
                  itemsGenerator: ->
                    item = 
                      close_on_click: editor_specific_behavior.close_on_click
                      itemsSource: ->
                        option_items = []
                        if not (gc = APP.modules.project_page?.gridControl())?
                          return option_items
                        field_options = field_def.grid_values 
                        
                        for option_id, option_def of field_options
                          option_items.push
                            bg_color: option_def.bg_color
                            field_id: field_id
                            id: option_id
                            is_nested_section: false
                            close_on_click: editor_specific_behavior.close_on_click
                            label: option_def.txt
                            label_i18n: option_def.txt_i18n
                            icon_type: editor_specific_behavior.icon_type
                            icon_val: editor_specific_behavior.icon_val
                            icon_class: editor_specific_behavior.icon_class
                            op: editor_specific_behavior.op
                        return option_items
                    return [item]
          return ret
      listingCondition: ->
        if not (gc = APP.modules.project_page?.gridControl())?
          return false

        return gc.isMultiSelectMode()

    # for field_id in bulk_set_options_fields
    #   @registerNestedSection "main", "bulk-set-options", "bulk-set-options-#{field_id}",
    #     position: 100 + i
    #     data:

    # @registerSectionItem "bulk-set-options", "bulk-set",
    #   position: 100
    #   data:
    #     label: "Bulk set"
    #     op: (item_data, task_id, task_path, field_val, dependencies_fields_vals, field_info) -> return 

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
          label_i18n: "projects_label"
        listingCondition: ->
          if not (gc = APP.modules.project_page?.gridControl())?
            return false

          if gc.isMultiSelectMode()
            return false

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
          label_i18n: (item_data, task_id, task_path, field_val, dependencies_fields_vals, field_info) ->
            if task_id? and APP.justdo_delivery_planner.isTaskObjProject(APP.collections.Tasks.findOne(task_id, {fields: {_id: 1, "#{JustdoDeliveryPlanner.task_is_project_field_name}": 1}}))
              return "unset_as_a_project_label"
            return "set_as_a_project_label"          
          op: (item_data, task_id, task_path, field_val, dependencies_fields_vals, field_info) ->
            APP.justdo_delivery_planner.toggleTaskIsProject task_id
            return 
          icon_type: "feather"
          icon_val: (item_data, task_id, task_path, field_val, dependencies_fields_vals, field_info) ->
            if task_id? and APP.justdo_delivery_planner.isTaskObjProject(APP.collections.Tasks.findOne(task_id, {fields: {_id: 1, "#{JustdoDeliveryPlanner.task_is_project_field_name}": 1}}))
              return "jd-folder-unset"
            return "folder"
        listingCondition: (item_definition, task_id, task_path, field_val, dependencies_fields_vals, field_info) ->
          return APP.justdo_permissions?.checkTaskPermissions("task-field-edit.p:dp:is_project", task_id)
      
      self.registerSectionItem "projects", "open-close-project",
        position: 300
        data:
          label: (item_data, task_id, task_path, field_val, dependencies_fields_vals, field_info) ->
            if dependencies_fields_vals?[JustdoDeliveryPlanner.task_is_archived_project_field_name]
              return "Reopen Project"
            else
              return "Close Project"
          label_i18n: (item_data, task_id, task_path, field_val, dependencies_fields_vals, field_info) ->
            if dependencies_fields_vals?[JustdoDeliveryPlanner.task_is_archived_project_field_name]
              return "repoen_project_label"
            else
              return "close_project_label"
          op: (item_data, task_id, task_path, field_val, dependencies_fields_vals, field_info) ->
            APP.justdo_delivery_planner.toggleTaskArchivedProjectState task_id
            return 
          icon_type: "feather"
          icon_val: "folder"
        listingCondition: (item_definition, task_id, task_path, field_val, dependencies_fields_vals, field_info) ->
          return APP.justdo_permissions?.checkTaskPermissions("task-field-edit.p:dp:is_archived_project", task_id) and
                    dependencies_fields_vals?[JustdoDeliveryPlanner.task_is_project_field_name] is true
      
      self.registerSectionItem "projects", "manage-projects",
        position: 100
        data:
          label: "Add to project"
          label_i18n: "add_to_project_label"
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

          cache_key = "justdo-has-projects::#{current_justdo_id}"

          if JustdoHelpers.sameTickCacheExists(cache_key)
            return JustdoHelpers.sameTickCacheGet(cache_key)

          options =
            fields:
              _id: 1
              "#{JustdoDeliveryPlanner.task_is_project_field_name}": 1

          justdo_has_projects = APP.collections.Tasks.findOne(query, options)?

          JustdoHelpers.sameTickCacheSet(cache_key, justdo_has_projects)

          return justdo_has_projects

      getAllJustdoActiveProjectsSortedByProjectName = (filter_state) ->
        active_item = APP.collections.Tasks.getDocNonReactive(JD.activeItemId())

        options = 
          active_only: true
          sort_by: {seqId: -1}

        if not _.isEmpty(filter_state)
          options.customize_query =
            title:
              $regex: new RegExp(JustdoHelpers.escapeRegExp(filter_state), "i")

        project_tasks = APP.justdo_delivery_planner.getKnownProjects(JD.activeJustdo({_id: 1})?._id, options, Meteor.userId())
        project_tasks = APP.justdo_delivery_planner.excludeProjectsCauseCircularChain project_tasks, JD.activeItemId()

        project_tasks = project_tasks.sort((project_task_a, project_task_b) =>
          is_in_project_a = project_task_a._id of active_item.parents
          is_in_project_b = project_task_b._id of active_item.parents
          if is_in_project_a and not is_in_project_b
            return -1
          else if not is_in_project_b and is_in_project_b
            return 1

          # https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/sort#sort_stability
          # https://archive.is/wip/Scyn6
          # JS Sort is stable, but for Edge, only since 2020, decided to ensure the {seqId: -1} sorting here. Daniel C.
          if project_task_a.seqId < project_task_b.seqId
            return 1
          else # 0 is not an option, since it is impossible to have equal seqIds
            return -1
        )
        
        return project_tasks
        
      addNewParentToTaskId = (task_id, new_parent_id, cb) ->
        project_page_module = APP.modules.project_page
        gc = project_page_module.gridControl()
        
        gc.saveAndExitActiveEditor() # Exit edit mode, if any, to make sure result will appear on tree (otherwise, will show only when exit edit mode)

        gc._performLockingOperation (releaseOpsLock, timedout) =>
          gc.addParent task_id, {parent: new_parent_id, order: 0}, (err) ->
            releaseOpsLock()

            cb?(err)

            return

          return

        return

      removeParent = (item_path, cb) ->
        project_page_module = APP.modules.project_page
        gc = project_page_module.gridControl()
        
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

          limit_rendered_items: true

          itemsGenerator: ->
            current_section_filter_state = self.getSectionFilterState("manage-active-projects")

            cache_key = "manage-active-projects::#{current_section_filter_state}"

            if JustdoHelpers.sameTickCacheExists(cache_key)
              return JustdoHelpers.sameTickCacheGet(cache_key)

            res = []

            active_item_id = JD.activeItemId()
            
            active_projects_docs = getAllJustdoActiveProjectsSortedByProjectName(current_section_filter_state)

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

                    label: -> return project_task_doc.title or ""
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

            JustdoHelpers.sameTickCacheSet(cache_key, res)
            return res
