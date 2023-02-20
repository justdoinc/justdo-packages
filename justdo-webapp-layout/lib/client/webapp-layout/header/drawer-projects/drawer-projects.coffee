Template.drawer_projects.onCreated ->
  @controller = @data.controller
  return

Template.drawer_projects.helpers
  projects: ->
    return Template.instance().controller.projects()

Template.drawer_projects.events
  "click .project-item": (e, tmpl) ->
    $(".global-wrapper").removeClass "drawer-open"
