APP.executeAfterAppLibCode ->
  module = APP.modules.project_page
  curProj = module.helpers.curProj
  projects = APP.projects

  Template.project_required_actions_dropdown_comp.helpers
    current_project: ->
      JD.activeJustdo({_id: 1})

  Template.required_actions_bell.helpers
    required_actions_count: ->
      projects.modules.required_actions.getCursor(@_id).count()

    current_project: ->
      curProj()
