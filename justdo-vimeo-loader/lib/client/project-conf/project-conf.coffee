_.extend JustdoVimeoLoader.prototype,
  registerConfigTemplate: ->
    APP.executeAfterAppClientCode ->
      project_page_module = APP.modules.project_page
      project_page_module.project_config_ui.registerConfigTemplate "justdo_vimeo_loader_project_config",
        section: "extensions"
        template: "justdo_vimeo_loader_project_config"
        priority: 100

    return

module_id = JustdoVimeoLoader.project_custom_feature_id

curProj = -> APP.modules.project_page.curProj()

Template.justdo_vimeo_loader_project_config.helpers
  isModuleEnabled: ->
    return curProj().isCustomFeatureEnabled(module_id)

  pluginName: ->
    return JustdoVimeoLoader.plugin_human_readable_name

Template.justdo_vimeo_loader_project_config.events
  "click .project-conf-justdo-vimeo-loader-config": ->
    proj = curProj()

    if proj.isCustomFeatureEnabled(module_id)
      proj.disableCustomFeatures(module_id)
    else
      proj.enableCustomFeatures(module_id)

    return