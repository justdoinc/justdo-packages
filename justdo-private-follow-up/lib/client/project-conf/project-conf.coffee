_.extend JustdoPrivateFollowUp.prototype,
  registerConfigTemplate: ->
    APP.executeAfterAppClientCode ->
      module = APP.modules.project_page
      module.project_config_ui.registerConfigTemplate "justdo_private_follow_up_project_config",
        section: "extensions"
        template: "justdo_private_follow_up_project_config"
        priority: 100

    return

module_id = JustdoPrivateFollowUp.project_custom_feature_id

curProj = -> APP.modules.project_page.curProj()

Template.justdo_private_follow_up_project_config.helpers
  isModuleEnabled: ->
    return curProj().isCustomFeatureEnabled(module_id)

Template.justdo_private_follow_up_project_config.events
  "click .project-conf-justdo-private-follow-up-config": ->
    proj = curProj()

    if proj.isCustomFeatureEnabled(module_id)
      curProj().disableCustomFeatures(module_id)
    else
      curProj().enableCustomFeatures(module_id)

