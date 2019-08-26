APP.executeAfterAppLibCode ->
  module = APP.modules.project_page
  curProj = module.helpers.curProj
  projects = APP.projects

  Template.project_required_actions_dropdown_comp.helpers
    current_project: ->
      curProj()?.getProjectDoc()

  Template.required_actions_bell.helpers
    required_actions_count: ->
      projects.modules.required_actions.getCursor(@_id).count()
