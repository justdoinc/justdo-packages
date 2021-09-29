_.extend JustdoTaskType.prototype,
  registerConfigTemplate: ->
    APP.executeAfterAppClientCode ->
      module = APP.modules.project_page
      module.project_config_ui.registerConfigTemplate "justdo_task_type_project_config",
        section: "extensions"
        template: "justdo_task_type_project_config"
        priority: 100

    return

module_id = JustdoTaskType.project_custom_feature_id

curProj = -> APP.modules.project_page.curProj()

Template.justdo_task_type_project_config.helpers
  isModuleEnabled: ->
    return curProj().isCustomFeatureEnabled(module_id)

  pluginName: ->
    return JustdoTaskType.plugin_human_readable_name

Template.justdo_task_type_project_config.events
  "click .project-conf-justdo-task-type-config": ->
    proj = curProj()

    if proj.isCustomFeatureEnabled(module_id)
      curProj().disableCustomFeatures(module_id)
    else
      curProj().enableCustomFeatures(module_id)
