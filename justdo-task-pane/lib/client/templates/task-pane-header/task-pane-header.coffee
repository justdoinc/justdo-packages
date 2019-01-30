# Do not use this package as example for how packages in
# JustDo should look like, refer to README.md to read more

APP.executeAfterAppLibCode ->
  module = APP.modules.project_page

  #
  # task_pane_header
  #

  getItemTitle = ->
    if (active_item_obj = module.activeItemObj({title: 1}))?
      if active_item_obj.title?
        return active_item_obj.title

      return "Untitled Task"

    return ""

  Template.task_pane_header.helpers module.template_helpers
  Template.task_pane_header.helpers
    title: -> getItemTitle()

    seq_id: -> module.activeItemObj({seqId: 1})?.seqId

    getPriorityColor: ->
      if not (priority = module.activeItemObj({priority: 1})?.priority)?
        return null

      return JustdoColorGradient.getColorRgbString(priority)
      

  Template.task_pane_header.events
    "click .copy-to-clipboard": (e) ->
      text = getItemTitle()

      if (seq_id = module.activeItemObj()?.seqId)?
        text = "Task ##{seq_id}: #{text}"

      clipboard.copy
        "text/plain": text
        "text/html": "<a href='#{window.location.href}'>#{text}</a>"

  #
  # task_pane_tab
  #
  Template.task_pane_tab.helpers module.template_helpers

  Template.task_pane_tab.events
    "click .task-pane-tab": -> module.setCurrentTaskPaneSectionId(@id)