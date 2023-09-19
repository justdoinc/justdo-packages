# Do not use this package as example for how packages in
# JustDo should look like, refer to README.md to read more

APP.executeAfterAppLibCode ->
  project_page_module = APP.modules.project_page

  #
  # task_pane_header
  #

  getItemTitle = ->
    if (active_item_obj = project_page_module.activeItemObj({title: 1}))?
      if active_item_obj.title?
        return active_item_obj.title

      return TAPi18n.__ "untitled_task_title" 

    return ""

  Template.task_pane_header.helpers project_page_module.template_helpers
  Template.task_pane_header.helpers
    title: ->
      if APP.modules.project_page.getActiveGridItemType() == "multi-select"
        return undefined

      return getItemTitle()

    seq_id: ->
      if APP.modules.project_page.getActiveGridItemType() == "multi-select"
        return undefined

      return project_page_module.activeItemObj({seqId: 1})?.seqId

    getPriorityColor: ->
      if APP.modules.project_page.getActiveGridItemType() == "multi-select"
        return null

      if not (priority = project_page_module.activeItemObj({priority: 1})?.priority)?
        return null

      return JustdoColorGradient.getColorRgbString(priority)
    
    getMaxTaskPaneHeaderWidth: ->
      project_page_module.invalidateOnWireframeStructureUpdates()

      if (calculatedTaskPaneWidth = $("#task-pane")?.attr("style")?.replace(/.*width: (\d+)px;.*/g, "$1"))?
        return calculatedTaskPaneWidth + "px"

      return "auto"

  Template.task_pane_header.events
    "click .copy-to-clipboard": (e) ->
      text = getItemTitle()

      if (seq_id = project_page_module.activeItemObj()?.seqId)?
        text = "Task ##{seq_id}: #{text}"

      clipboard.copy
        "text/plain": text
        "text/html": "<a href='#{window.location.href}'>#{text}</a>"

      return

    "click .seqid-copy-to-clipboard": (e) ->
      if (seq_id = project_page_module.activeItemObj()?.seqId)?
        clipboard.copy
          "text/plain": "#" + seq_id
          "text/html": "<a href='#{window.location.href}'>##{seq_id}</a>"

      return

  #
  # task_pane_tab
  #
  Template.task_pane_tab.helpers project_page_module.template_helpers

  Template.task_pane_tab.events
    "click .task-pane-tab": -> project_page_module.setCurrentTaskPaneSectionId(@id)