_.extend CustomJustdoTasksLocks.prototype,
  registerConfigTemplate: ->
    # APP.executeAfterAppClientCode ->
    #   module = APP.modules.project_page
    #   module.project_config_ui.registerConfigTemplate "custom_justdo_tasks_locks_project_config",
    #     section: "extensions"
    #     template: "custom_justdo_tasks_locks_project_config"
    #     priority: 100

    # return

module_id = CustomJustdoTasksLocks.project_custom_feature_id

curProj = -> APP.modules.project_page.curProj()

Template.custom_justdo_tasks_locks_project_config.helpers
  isModuleEnabled: ->
    return curProj().isCustomFeatureEnabled(module_id)

  pluginName: ->
    return CustomJustdoTasksLocks.plugin_human_readable_name

Template.custom_justdo_tasks_locks_project_config.events
  "click .project-conf-custom-justdo-tasks-locks-config": ->
    proj = curProj()

    if proj.isCustomFeatureEnabled(module_id)
      curProj().disableCustomFeatures(module_id)
    else
      curProj().enableCustomFeatures(module_id)
