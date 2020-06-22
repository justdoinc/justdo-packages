_.extend JustdoCustomPlugins.prototype,
  registerConfigTemplate: ->
    APP.executeAfterAppClientCode ->
      module = APP.modules.project_page
      module.project_config_ui.registerConfigTemplate "justdo_custom_plugins_project_config",
        section: "extensions"
        template: "justdo_custom_plugins_project_config"
        priority: 100

    return

module_id = JustdoCustomPlugins.project_custom_feature_id

curProj = -> APP.modules.project_page.curProj()

Template.justdo_custom_plugins_project_config.helpers
  isModuleEnabled: ->
    return curProj().isCustomFeatureEnabled(module_id)

  pluginName: ->
    return JustdoCustomPlugins.plugin_human_readable_name

Template.justdo_custom_plugins_project_config.events
  "click .project-conf-justdo-custom-plugins-config": ->
    proj = curProj()

    if proj.isCustomFeatureEnabled(module_id)
      curProj().disableCustomFeatures(module_id)
    else
      curProj().enableCustomFeatures(module_id)
