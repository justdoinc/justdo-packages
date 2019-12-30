Template.project_operations_toolbar.onRendered ->
  priority_slider = Template.justdo_priority_slider.getInstance "operations_toolbar_priority_slider"
  
  priority_slider.onChange (value, tpl) ->
    task_id = APP.modules.project_page.activeItemId()
    if task_id?
      APP.collections.Tasks.update task_id, {$set: {priority: value}}

    return

  @autorun =>
    if (task = APP.modules.project_page.activeItemObj())?
      priority_slider.enable()
      priority_slider.setValue task.priority, false
    else
      priority_slider.disable()

    return

  return