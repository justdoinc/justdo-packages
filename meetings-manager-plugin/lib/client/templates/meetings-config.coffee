curProj = -> APP.modules.project_page.curProj()

module_id = "meetings_module"

Template.meetings_config.helpers
  isModuleEnabled: ->
    return APP.modules.project_page.curProj().isCustomFeatureEnabled(module_id)

Template.meetings_config.events
  "click .project-conf-meetings-config": ->
    proj = curProj()

    if proj.isCustomFeatureEnabled(module_id)
      curProj().disableCustomFeatures(module_id)
    else
      curProj().enableCustomFeatures(module_id)
