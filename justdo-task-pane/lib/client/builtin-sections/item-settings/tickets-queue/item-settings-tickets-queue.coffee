# Do not use this package as example for how packages in
# JustDo should look like, refer to README.md to read more

APP.executeAfterAppLibCode ->
  module = APP.modules.project_page

  Template.task_pane_item_settings_tq.helpers
    is_tickets_queue: ->
      if (active_obj = module.activeItemObj({is_tickets_queue: 1}))?
        return active_obj.is_tickets_queue == true

      return false

  Template.task_pane_item_settings_tq.events
    "change #task-is-tickets-queue": (e) ->
      task_id = module.activeItemId()

      if e.target.checked
        APP.collections.Tasks.update task_id, {$set: {is_tickets_queue: true}}
      else
        APP.collections.Tasks.update task_id, {$set: {is_tickets_queue: false}}