_.extend JustdoUserActivePosition.prototype,
  registerConfigTemplate: ->
    APP.executeAfterAppClientCode ->
      project_page_module = APP.modules.project_page
      project_page_module.project_config_ui.registerConfigTemplate "justdo_user_active_position_project_config",
        section: "extensions"
        template: "justdo_user_active_position_project_config"
        priority: 10000

    return

module_id = JustdoUserActivePosition.project_custom_feature_id

curProj = -> APP.modules.project_page.curProj()

Template.justdo_user_active_position_project_config.helpers
  isModuleEnabled: ->
    return APP.justdo_user_active_position.isModuleEnabled()

  pluginName: ->
    return JustdoUserActivePosition.plugin_human_readable_name

Template.justdo_user_active_position_project_config.events
  "click .project-conf-justdo-user-active-position-config": ->
    proj = curProj()

    if APP.justdo_user_active_position.isModuleEnabled()
      curProj().disableCustomFeatures(module_id)
    else
      curProj().enableCustomFeatures(module_id)
