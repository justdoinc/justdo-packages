Template.justdo_project_pane_expanded.onRendered ->
  $(".justdo-project-pane-container").resizable
    handles: "n"

    minHeight: JustdoProjectPane.min_expanded_height

    resize: (event, ui) ->
      APP.justdo_project_pane.setHeight(ui.size.height)
      Tracker.flush()

      return

  return

Template.justdo_project_pane_expanded.onDestroyed ->
  $(".justdo-project-pane-container").resizable("destroy")

  return

Template.justdo_project_pane.helpers
  isExpanded: -> APP.justdo_project_pane.isExpanded()

Template.justdo_project_pane.events
  "click .collapsed": -> APP.justdo_project_pane.expand()

Template.justdo_project_pane_expanded.helpers
  getActiveTabId: -> APP.justdo_project_pane.getActiveTabId()

  getActiveTabTemplateName: -> APP.justdo_project_pane.getActiveTabTemplateName()

Template.justdo_project_pane_expanded_header.helpers
  getTabs: -> APP.justdo_project_pane.getTabs()

  getActiveTabId: -> APP.justdo_project_pane.getActiveTabId()

Template.justdo_project_pane_expanded_header.events
  "click .project-pane-tab": (e) -> APP.justdo_project_pane.setActiveTab $(e.target).attr("tab-id")

  "click .justdo-project-pane-close": (e) -> APP.justdo_project_pane.collapse()

