_.extend JustdoSupportCenter.prototype,
  registerConfigTemplate: ->
    APP.executeAfterAppClientCode ->
      project_page_module = APP.modules.project_page
      project_page_module.project_config_ui.registerConfigTemplate "justdo_support_center_project_config",
        section: "extensions"
        template: "justdo_support_center_project_config"
        priority: 100

    return

module_id = JustdoSupportCenter.project_custom_feature_id

curProj = -> APP.modules.project_page.curProj()

Template.justdo_support_center_project_config.helpers
  isModuleEnabled: ->
    return curProj().isCustomFeatureEnabled(module_id)

  pluginName: ->
    return JustdoSupportCenter.plugin_human_readable_name

Template.justdo_support_center_project_config.events
  "click .project-conf-justdo-support-center-config": ->
    proj = curProj()

    if proj.isCustomFeatureEnabled(module_id)
      curProj().disableCustomFeatures(module_id)
    else
      curProj().enableCustomFeatures(module_id)
