_.extend JustdoKanban.prototype,
  registerConfigTemplate: ->
    APP.executeAfterAppClientCode ->
      module = APP.modules.project_page
      module.project_config_ui.registerConfigTemplate "justdo_kanban_project_config",
        section: "extensions"
        template: "justdo_kanban_project_config"
        priority: 100

    return

module_id = JustdoKanban.project_custom_feature_id

curProj = -> APP.modules.project_page.curProj()

Template.justdo_kanban_project_config.helpers
  isModuleEnabled: ->
    return curProj().isCustomFeatureEnabled(module_id)

  pluginName: ->
    return JustdoKanban.plugin_human_readable_name

Template.justdo_kanban_project_config.events
  "click .project-conf-justdo-kanban-config": ->
    proj = curProj()

    if proj.isCustomFeatureEnabled(module_id)
      curProj().disableCustomFeatures(module_id)
    else
      curProj().enableCustomFeatures(module_id)
