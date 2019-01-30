APP.executeAfterAppLibCode ->
  module = APP.modules.project_page
  curProj = module.helpers.curProj
  projects = APP.projects

  Template.project_required_actions_dropdown_comp.helpers
    current_project: ->
      curProj()?.getProjectDoc()

  required_actions_dropdown = null

  Template.project_required_actions_dropdown_comp.onRendered ->
    required_actions_dropdown = new module.RequiredActionsDropdown(@firstNode) # defined in ./required-actions-dropdown/required-actions-dropdown.coffee

  Template.project_required_actions_dropdown_comp.onDestroyed ->
    if required_actions_dropdown?
      required_actions_dropdown.destroy()
      required_actions_dropdown = null

  Template.required_actions_bell.helpers
    required_actions_count: ->
      projects.modules.required_actions.getCursor(@_id).count()
