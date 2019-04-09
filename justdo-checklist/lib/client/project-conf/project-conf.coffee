_.extend JustdoChecklist.prototype,
  registerConfigTemplate: ->
    APP.executeAfterAppClientCode ->
      module = APP.modules.project_page
      module.project_config_ui.registerConfigTemplate "justdo_checklist_project_config",
        section: "extensions"
        template: "justdo_checklist_project_config"
        priority: 100

    return

module_id = JustdoChecklist.project_custom_feature_id

curProj = -> APP.modules.project_page.curProj()

Template.justdo_checklist_project_config.helpers
  pluginName: ->
    return JustdoChecklist.plugin_human_readable_name

  isModuleEnabled: ->
    return curProj().isCustomFeatureEnabled(module_id)

Template.justdo_checklist_project_config.events
  "click .project-conf-justdo-checklist-config": ->
    proj = curProj()

    if proj.isCustomFeatureEnabled(module_id)
      curProj().disableCustomFeatures(module_id)
    else
      curProj().enableCustomFeatures(module_id)

    return