_.extend JustdoNewProjectTemplates.prototype,
  registerConfigTemplate: ->
    APP.executeAfterAppClientCode ->
      module = APP.modules.project_page
      module.project_config_ui.registerConfigTemplate "justdo_new_project_templates_project_config",
        section: "extensions"
        template: "justdo_new_project_templates_project_config"
        priority: 100

    return

module_id = JustdoNewProjectTemplates.project_custom_feature_id

curProj = -> APP.modules.project_page.curProj()

Template.justdo_new_project_templates_project_config.helpers
  isModuleEnabled: ->
    return curProj().isCustomFeatureEnabled(module_id)

  pluginName: ->
    return JustdoNewProjectTemplates.plugin_human_readable_name

Template.justdo_new_project_templates_project_config.events
  "click .project-conf-justdo-new-project-templates-config": ->
    proj = curProj()

    if proj.isCustomFeatureEnabled(module_id)
      curProj().disableCustomFeatures(module_id)
    else
      curProj().enableCustomFeatures(module_id)
