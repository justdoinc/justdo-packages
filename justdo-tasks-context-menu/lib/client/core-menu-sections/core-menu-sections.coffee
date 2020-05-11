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
        op: ->
          APP.modules.project_page.performOp("addSiblingTask")

          return
        icon_type: "feather"
        icon_val: "plus"

      listingCondition: -> _.isEmpty(APP.modules.project_page.getUnfulfilledOpReq("addSiblingTask"))

    @registerSectionItem "main", "new-child-task",
      position: 200
      data:
        label: "New Child Task"
        op: ->
          APP.modules.project_page.performOp("addSubTask")

          return
        icon_type: "feather"
        icon_val: "corner-down-right"
    
    @registerSectionItem "main", "zoon-in",
      position: 300
      data:
        label: "Zoom in"
        op: ->
          APP.modules.project_page.performOp("zoomIn")

          return
        icon_type: "feather"
        icon_val: "zoom-in"
    
    @registerMainSection "projects",
      position: 200
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
        op: -> 
          APP.justdo_delivery_planner.toggleTaskIsProject APP.modules.project_page.activeItemId()
          return 
        icon_type: "feather"
        icon_val: "folder"
      listingCondition: -> 
        return (task = APP.modules.project_page.activeItemObj())? and not (task["p:dp:is_project"] == true)
    
    @registerSectionItem "projects", "unset-as-a-project",
      position: 200
      data:
        label: "Unset as a Project"
        op: ->
          APP.justdo_delivery_planner.toggleTaskIsProject APP.modules.project_page.activeItemId()
          return
        icon_type: "feather"
        icon_val: "folder-minus"
      listingCondition: -> 
        return (task = APP.modules.project_page.activeItemObj())? and (task["p:dp:is_project"] == true)

    @registerSectionItem "projects", "assign-to-project",
      position: 300
      data:
        label: "Assign to Project"
        is_nested_section: true
        icon_type: "feather"
        icon_val: "corner-right-down"
    
    @registerNestedSection "projects", "assign-to-project", "assign-to-project-items",
      position: 100

    @_getTaskAvailableAssignProjectList = =>
      if not current_project_id = APP.modules.project_page.curProj()?.id
        return

      if not (active_item_obj = APP.modules.project_page.activeItemObj())?
        return

      exclude_tasks = [active_item_obj._id].concat(_.keys active_item_obj.parents)

      project_tasks = APP.justdo_delivery_planner.getKnownProjects(current_project_id, {active_only: true, exclude_tasks: exclude_tasks}, Meteor.userId())

      gc = APP.modules.project_page.mainGridControl()

      grid_data = gc?._grid_data

      # Remove projects that are tasks to which we can't be assigned as a child due to circular
      # chain.
      project_tasks = _.filter project_tasks, (task) ->
        for task_path in grid_data.getAllCollectionItemIdPaths(task._id)
          reg = new RegExp("/#{active_item_obj._id}/")

          if reg.test(task_path)
            return false

        return true

      return project_tasks
    
    @_addNewParentToActiveItemId = (new_parent_id, cb) ->
      module = APP.modules.project_page
      gc = module.gridControl()
      grid_data = gc?._grid_data

      if grid_data?
        gc?.saveAndExitActiveEditor() # Exit edit mode, if any, to make sure result will appear on tree (otherwise, will show only when exit edit mode)

        current_item_id = module.activeItemId()

        gc._performLockingOperation (releaseOpsLock, timedout) =>
          gc.addParent current_item_id, {parent: new_parent_id, order: 0}, (err) ->
            releaseOpsLock()

            cb?(err)
      else
        APP.logger.error "Context: couldn't retrieve grid_data object"

      return

    project_items_to_unregister = []
    Tracker.autorun =>
      for item in project_items_to_unregister
        @unregisterSectionItem "assign-to-project-items", item
      project_items_to_unregister = []
      
      if (projects_list = @_getTaskAvailableAssignProjectList())?
        i = 1
        for project in projects_list
          @registerSectionItem "assign-to-project-items", project._id,
            position: i * 100
            data:
              label: "##{project.seqId} #{if project.title? then project.title else ""}"
              op: ->
                self._addNewParentToActiveItemId project._id, (err) ->
                  if err?
                    console.log err
                  return
                return
          project_items_to_unregister.push project._id
          i = i + 1

        if i == 1
          @registerSectionItem "assign-to-project-items", "no-projects-available",
            position: 100
            data:
              label: "No projects available for assigning."
              op: -> return
          project_items_to_unregister.push "no-projects-available"

      return

    return