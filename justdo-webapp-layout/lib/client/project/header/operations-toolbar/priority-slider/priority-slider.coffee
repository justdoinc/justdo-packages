APP.executeAfterAppLibCode ->
  Template.project_operations_priority_slider.onRendered ->
    task_priority_slider = new genericSlider "selected-task-priority", 0.5, (new_val, is_final) ->
      v = Math.round(100 * new_val)

      task_id = APP.modules.project_page.activeItemId()
      if task_id?
        if is_final
          APP.collections.Tasks.update task_id, {$set: {priority: v}}
        else
          APP.collections.Tasks._collection.update task_id, {$set: {priority: v}}

    # Make the task_priority_slider reactive
    @autorun ->
      task_id = APP.modules.project_page.activeItemId()
      if task_id?
        item = APP.collections.Tasks.findOne task_id
        if item?
          priority = item.priority or 0
          task_priority_slider.set (priority / 100), false, true

