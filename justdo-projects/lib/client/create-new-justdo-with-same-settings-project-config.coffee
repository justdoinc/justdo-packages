curProj = -> APP.modules.project_page.curProj()

custom_feature_id = "create-new-justdo-with-same-settings"
Template.create_new_justdo_with_same_settings_project_config.helpers
  isModuleEnabled: ->
    return curProj().isCustomFeatureEnabled(custom_feature_id)

  pluginName: ->
    return "Create new justdo with same settings"

Template.create_new_justdo_with_same_settings_project_config.events
  "click .project-conf-justdo-risks-config": ->
    proj = curProj()

    if proj.isCustomFeatureEnabled(custom_feature_id)
      curProj().disableCustomFeatures(custom_feature_id)
    else
      curProj().enableCustomFeatures(custom_feature_id)

    return