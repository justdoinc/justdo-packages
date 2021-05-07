Template.manage_active_projects_jump_to_proj.helpers
  isBelongingToProject: ->
    [item_data, task_id, task_path, field_val, dependencies_fields_vals, field_info] = @

    if not task_id?
      return

    query =
      _id: task_id

    options =
      fields:
        _id: 1
        parents: 1

    task_doc = APP.collections.Tasks.findOne(query, options) # We could have used gc._grid_data.items_by_id[task_id].parents, but we need reativity anyways

    if item_data.id of task_doc.parents
      return true
    
    return false

Template.manage_active_projects_jump_to_proj.events
  "click .jump-to-task-in-proj": (e) ->
    e.stopImmediatePropagation()

    [item_data, task_id, task_path, field_val, dependencies_fields_vals, field_info] = @

    project_task_id = item_data.id

    # Try to find project_task_id path in the current grid
    gc = APP.modules.project_page.gridControl()
    if (project_path = gc?._grid_data?.getCollectionItemIdPath(project_task_id))?
      # We found a path to project_task_id in the current tab, jump to it.
      gc.activatePath(project_path + task_id + "/")
    else
      # Couldn't find in the active tab, zoom into project, and select the task
      tab_id = "sub-tree"

      gcm = APP.modules.project_page.getCurrentGcm()

      gcm.activateTabWithSectionsState(tab_id, {global: {"root-item": project_task_id}})

      gcm.setPath([tab_id, "/#{project_task_id}/#{task_id}/"])

    APP.justdo_tasks_context_menu.hide()

    return