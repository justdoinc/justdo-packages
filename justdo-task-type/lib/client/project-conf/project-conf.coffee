_.extend JustdoTaskType.prototype,
  registerConfigTemplate: ->
    APP.executeAfterAppClientCode ->
      module = APP.modules.project_page
      module.project_config_ui.registerConfigTemplate "justdo_task_type_project_config",
        section: "extensions"
        template: "justdo_task_type_project_config"
        priority: 10000

    return

module_id = JustdoTaskType.project_custom_feature_id

curProj = -> APP.modules.project_page.curProj()

Template.justdo_task_type_project_config.helpers
  isModuleEnabled: ->
    return curProj().isCustomFeatureEnabled(module_id)

  pluginName: ->
    return JustdoTaskType.plugin_human_readable_name

  showConfig: ->
    # The AND clause is to only allow disabling the plugin where it was already installed
    # following a decision to wait with making this plugin available under our general release
    # See task: #11776: Don't allow enabling the Task Type plugin from the JustDo settings
    # (allow only deselect where it is already enabled)
    return (not JustdoTaskType.plugin_integral_part_of_justdo) and curProj().isCustomFeatureEnabled(module_id)

Template.justdo_task_type_project_config.events
  "click .project-conf-justdo-task-type-config": ->
    proj = curProj()

    if proj.isCustomFeatureEnabled(module_id)
      curProj().disableCustomFeatures(module_id)
    else
      curProj().enableCustomFeatures(module_id)
