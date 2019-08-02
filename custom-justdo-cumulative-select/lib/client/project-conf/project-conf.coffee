_.extend CustomJustdoCumulativeSelect.prototype,
  registerConfigTemplate: ->
    APP.executeAfterAppClientCode ->
      module = APP.modules.project_page
      module.project_config_ui.registerConfigTemplate "custom_justdo_cumulative_select_project_config",
        section: "extensions"
        template: "custom_justdo_cumulative_select_project_config"
        priority: 100

    return

module_id = CustomJustdoCumulativeSelect.project_custom_feature_id

curProj = -> APP.modules.project_page.curProj()

Template.custom_justdo_cumulative_select_project_config.helpers
  isModuleEnabled: ->
    return curProj().isCustomFeatureEnabled(module_id)

  pluginName: ->
    return CustomJustdoCumulativeSelect.plugin_human_readable_name

Template.custom_justdo_cumulative_select_project_config.events
  "click .project-conf-custom-justdo-cumulative-select-config": ->
    proj = curProj()

    if proj.isCustomFeatureEnabled(module_id)
      proj.disableCustomFeatures(module_id)
    else
      proj.enableCustomFeatures(module_id)

