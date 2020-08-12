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

    gcm = APP.modules.project_page.getCurrentGcm()

    # TODO activateCollectionItemIdInCurrentPathOrFallbackToMainTab isn't respecting properly
    # item_data.id + "/"  when we are in the 3rd level.
    gcm.activateCollectionItemIdInCurrentPathOrFallbackToMainTab(item_data.id + "/" + task_id)

    APP.justdo_tasks_context_menu.hide()

    return