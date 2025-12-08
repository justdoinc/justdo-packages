Template.projects_collection_jump_to_pc.helpers
  isBelongingToProjectsCollection: ->
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

Template.projects_collection_jump_to_pc.events
  "click .jump-to-task-in-pc": (e) ->
    e.stopImmediatePropagation()

    [item_data, task_id, task_path, field_val, dependencies_fields_vals, field_info] = @

    pc_task_id = item_data.id

    # Try to find pc_task_id path in the current grid
    gc = APP.modules.project_page.gridControl()
    if (pc_path = gc?._grid_data?.getCollectionItemIdPath(pc_task_id))?
      # We found a path to pc_task_id in the current tab, jump to it.
      gc.activatePath(pc_path + task_id + "/")
    else
      # Couldn't find in the active tab, zoom into projects collection, and select the task
      tab_id = "sub-tree"

      gcm = APP.modules.project_page.getCurrentGcm()

      gcm.activateTabWithSectionsState(tab_id, {global: {"root-item": pc_task_id}})

      gcm.setPath([tab_id, "/#{pc_task_id}/#{task_id}/"])

    APP.justdo_tasks_context_menu.hide()

    return

