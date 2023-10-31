_.extend CustomJustdoSaveDefaultView.prototype,
  registerConfigTemplate: ->
    APP.executeAfterAppClientCode ->
      project_page_module = APP.modules.project_page
      project_page_module.project_config_ui.registerConfigTemplate "custom_justdo_save_default_view_project_config",
        section: "extensions"
        template: "custom_justdo_save_default_view_project_config"
        priority: 1000

    return

module_id = CustomJustdoSaveDefaultView.project_custom_feature_id

curProj = -> APP.modules.project_page.curProj()

Template.custom_justdo_save_default_view_project_config.helpers
  isModuleEnabled: ->
    return curProj().isCustomFeatureEnabled(module_id)

  pluginName: ->
    return CustomJustdoSaveDefaultView.plugin_human_readable_name

Template.custom_justdo_save_default_view_project_config.events
  "click .project-conf-custom-justdo-save-default-view-config": ->
    proj = curProj()

    if proj.isCustomFeatureEnabled(module_id)
      curProj().disableCustomFeatures(module_id)
    else
      curProj().enableCustomFeatures(module_id)
