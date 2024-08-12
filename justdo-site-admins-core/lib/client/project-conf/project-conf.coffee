_.extend JustdoSiteAdminsCore.prototype,
  registerConfigTemplate: ->
    APP.executeAfterAppClientCode ->
      project_page_module = APP.modules.project_page
      project_page_module.project_config_ui.registerConfigTemplate "justdo_site_admins_core_project_config",
        section: "extensions"
        template: "justdo_site_admins_core_project_config"
        priority: 100

    return

module_id = JustdoSiteAdminsCore.project_custom_feature_id

curProj = -> APP.modules.project_page.curProj()

Template.justdo_site_admins_core_project_config.helpers
  isModuleEnabled: ->
    return curProj().isCustomFeatureEnabled(module_id)

  pluginName: ->
    return JustdoSiteAdminsCore.plugin_human_readable_name

Template.justdo_site_admins_core_project_config.events
  "click .project-conf-justdo-site-admins-core-config": ->
    proj = curProj()

    if proj.isCustomFeatureEnabled(module_id)
      curProj().disableCustomFeatures(module_id)
    else
      curProj().enableCustomFeatures(module_id)
