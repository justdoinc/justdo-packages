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

  "click .settings-btn": ->
    APP.meetings_manager_plugin.openSettingsDialog()
    return false


Template.meetings_settings.helpers
  isAllowMeetingsDeletion: ->
    return not APP.modules.project_page.curProj()?.getProjectConfiguration()?.block_meetings_deletion

Template.meetings_settings.events
  "change .allow-meetings-deletion": (e, tpl) ->

    APP.modules.project_page.curProj().configureProject
      block_meetings_deletion: not e.target.checked

    return