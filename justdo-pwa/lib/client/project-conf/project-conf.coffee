_.extend JustdoPwa.prototype,
  registerConfigTemplate: ->
    APP.executeAfterAppClientCode ->
      project_page_module = APP.modules.project_page
      project_page_module.project_config_ui.registerConfigTemplate "justdo_pwa_project_config",
        section: "extensions"
        template: "justdo_pwa_project_config"
        priority: 100

    return

module_id = JustdoPwa.project_custom_feature_id

curProj = -> APP.modules.project_page.curProj()

Template.justdo_pwa_project_config.helpers
  isModuleEnabled: ->
    return curProj().isCustomFeatureEnabled(module_id)

  pluginName: ->
    return JustdoPwa.plugin_human_readable_name

Template.justdo_pwa_project_config.events
  "click .project-conf-justdo-pwa-config": ->
    proj = curProj()

    if proj.isCustomFeatureEnabled(module_id)
      curProj().disableCustomFeatures(module_id)
    else
      curProj().enableCustomFeatures(module_id)
