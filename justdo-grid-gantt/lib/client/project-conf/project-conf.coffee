_.extend JustdoGridGantt.prototype,
  registerConfigTemplate: ->
    APP.executeAfterAppClientCode ->
      module = APP.modules.project_page
      module.project_config_ui.registerConfigTemplate "justdo_grid_gantt_project_config",
        section: "extensions"
        template: "justdo_grid_gantt_project_config"
        priority: 100

    return

module_id = JustdoGridGantt.project_custom_feature_id

curProj = -> APP.modules.project_page.curProj()

Template.justdo_grid_gantt_project_config.helpers
  isModuleEnabled: ->
    return curProj().isCustomFeatureEnabled(module_id)

  pluginName: ->
    return JustdoGridGantt.plugin_human_readable_name

Template.justdo_grid_gantt_project_config.events
  "click .project-conf-justdo-grid-gantt-config": ->
    proj = curProj()

    if proj.isCustomFeatureEnabled(module_id)
      proj.disableCustomFeatures(module_id)
    else
      proj.enableCustomFeatures(module_id)

