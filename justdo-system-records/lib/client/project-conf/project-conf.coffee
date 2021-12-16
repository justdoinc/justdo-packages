_.extend JustdoSystemRecords.prototype,
  registerConfigTemplate: ->
    APP.executeAfterAppClientCode ->
      module = APP.modules.project_page
      module.project_config_ui.registerConfigTemplate "justdo_system_records_project_config",
        section: "extensions"
        template: "justdo_system_records_project_config"
        priority: 100

    return

module_id = JustdoSystemRecords.project_custom_feature_id

curProj = -> APP.modules.project_page.curProj()

Template.justdo_system_records_project_config.helpers
  isModuleEnabled: ->
    return curProj().isCustomFeatureEnabled(module_id)

  pluginName: ->
    return JustdoSystemRecords.plugin_human_readable_name

Template.justdo_system_records_project_config.events
  "click .project-conf-justdo-system-records-config": ->
    proj = curProj()

    if proj.isCustomFeatureEnabled(module_id)
      curProj().disableCustomFeatures(module_id)
    else
      curProj().enableCustomFeatures(module_id)
