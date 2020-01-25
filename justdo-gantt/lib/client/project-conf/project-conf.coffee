_.extend JustdoGantt.prototype,
  registerConfigTemplate: ->
    APP.executeAfterAppClientCode ->
      module = APP.modules.project_page
      module.project_config_ui.registerConfigTemplate "justdo_gantt_project_config",
        section: "extensions"
        template: "justdo_gantt_project_config"
        priority: 100

    return

module_id = JustdoGantt.project_custom_feature_id

curProj = -> APP.modules.project_page.curProj()

Template.justdo_gantt_project_config.helpers
  isModuleEnabled: ->
    return curProj().isCustomFeatureEnabled(module_id)

  pluginName: ->
    return JustdoGantt.plugin_human_readable_name

Template.justdo_gantt_project_config.events
  "click .project-conf-justdo-gantt-config": ->
    proj = curProj()

    if proj.isCustomFeatureEnabled(module_id)
      curProj().disableCustomFeatures(module_id)
    else
      curProj().enableCustomFeatures(module_id)
