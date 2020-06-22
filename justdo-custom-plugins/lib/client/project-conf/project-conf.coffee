_.extend JustdoCustomPlugins.prototype,
  registerConfigTemplate: ->
    APP.executeAfterAppClientCode ->
      module = APP.modules.project_page
      module.project_config_ui.registerConfigTemplate "justdo_custom_plugins_project_config",
        section: "extensions"
        template: "justdo_custom_plugins_project_config"
        priority: 10000

    return

curProj = -> APP.modules.project_page.curProj()

Template.justdo_custom_plugins_project_config.helpers
  getListedCustomPlugins: ->
    return _.filter APP.justdo_custom_plugins.getCustomPlugins(), (custom_plugin) -> custom_plugin.show_in_extensions_list

Template.justdo_custom_plugin_project_config.helpers
  isModuleEnabled: ->
    return curProj().isCustomFeatureEnabled(@custom_plugin_id)

  pluginName: ->
    return @custom_plugin_readable_name

Template.justdo_custom_plugin_project_config.events
  "click .project-conf-justdo-custom-plugin-config": ->
    proj = curProj()

    if proj.isCustomFeatureEnabled(@custom_plugin_id)
      curProj().disableCustomFeatures(@custom_plugin_id)
    else
      curProj().enableCustomFeatures(@custom_plugin_id)

    return