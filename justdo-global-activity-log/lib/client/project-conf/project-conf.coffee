_.extend JustdoGlobalActivityLog.prototype,
  registerConfigTemplate: ->
    APP.executeAfterAppClientCode ->
      module = APP.modules.project_page
      module.project_config_ui.registerConfigTemplate "justdo_global_activity_log_project_config",
        section: "extensions"
        template: "justdo_global_activity_log_project_config"
        priority: 1000

    return

module_id = JustdoGlobalActivityLog.project_custom_feature_id

curProj = -> APP.modules.project_page.curProj()

Template.justdo_global_activity_log_project_config.helpers
  isModuleEnabled: ->
    return APP.modules.project_page.curProj().isCustomFeatureEnabled(module_id)

Template.justdo_global_activity_log_project_config.events
  "click .project-conf-justdo-global-activity-log-config": ->
    proj = curProj()

    if proj.isCustomFeatureEnabled(module_id)
      curProj().disableCustomFeatures(module_id)
    else
      curProj().enableCustomFeatures(module_id)

