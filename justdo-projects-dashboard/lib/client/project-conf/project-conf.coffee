_.extend JustdoProjectsDashboard.prototype,
  registerConfigTemplate: ->
    APP.executeAfterAppClientCode ->
      project_page_module = APP.modules.project_page
      project_page_module.project_config_ui.registerConfigTemplate "justdo_projects_dashboard_project_config",
        section: "extensions"
        template: "justdo_projects_dashboard_project_config"
        priority: 500

    return

module_id = JustdoProjectsDashboard.project_custom_feature_id

curProj = -> APP.modules.project_page.curProj()

Template.justdo_projects_dashboard_project_config.helpers
  isModuleEnabled: ->
    return curProj().isCustomFeatureEnabled(module_id)

  pluginName: ->
    return JustdoProjectsDashboard.plugin_human_readable_name

Template.justdo_projects_dashboard_project_config.events
  "click .project-conf-justdo-projects-dashboard-config": ->
    proj = curProj()

    if proj.isCustomFeatureEnabled(module_id)
      curProj().disableCustomFeatures(module_id)
    else
      curProj().enableCustomFeatures(module_id)
