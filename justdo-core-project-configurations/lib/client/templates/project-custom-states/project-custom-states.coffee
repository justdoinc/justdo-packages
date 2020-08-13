# HELPERS
Template.project_custom_states.helpers
  activeStates: ->
    return APP.modules.project_page.curProj().getCustomStates()

  hiddenStates: ->
    return APP.modules.project_page.curProj().getHiddenCustomStates()
