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
    title: ->
      if APP.modules.project_page.getActiveGridItemType() == "multi-select"
        return undefined

      return getItemTitle()

    seq_id: ->
      if APP.modules.project_page.getActiveGridItemType() == "multi-select"
        return undefined

      return module.activeItemObj({seqId: 1})?.seqId

    getPriorityColor: ->
      if APP.modules.project_page.getActiveGridItemType() == "multi-select"
        return null

      if not (priority = module.activeItemObj({priority: 1})?.priority)?
        return null

      return JustdoColorGradient.getColorRgbString(priority)
    
    getMaxTaskPaneHeaderWidth: ->
      module.invalidateOnWireframeStructureUpdates()

      if (calculatedTaskPaneWidth = $("#task-pane")?.attr("style")?.replace(/.*width: (\d+)px;.*/g, "$1"))?
        return calculatedTaskPaneWidth + "px"

      return "auto"

  Template.task_pane_header.events
    "click .copy-to-clipboard": (e) ->
      text = getItemTitle()

      if (seq_id = module.activeItemObj()?.seqId)?
        text = "Task ##{seq_id}: #{text}"

      clipboard.copy
        "text/plain": text
        "text/html": "<a href='#{window.location.href}'>#{text}</a>"

    "click .seqid-copy-to-clipboard": (e) ->
      if (seq_id = module.activeItemObj()?.seqId)?
        clipboard.copy
          "text/plain": seq_id
          "text/html": "<a href='#{window.location.href}'>#seq_id</a>"


  #
  # task_pane_tab
  #
  Template.task_pane_tab.helpers module.template_helpers

  Template.task_pane_tab.events
    "click .task-pane-tab": -> module.setCurrentTaskPaneSectionId(@id)