_.extend JustdoI18n.prototype,
  registerConfigTemplate: ->
    APP.executeAfterAppClientCode ->
      module = APP.modules.project_page
      module.project_config_ui.registerConfigTemplate "justdo_i18n_project_config",
        section: "extensions"
        template: "justdo_i18n_project_config"
        priority: 100

    return

module_id = JustdoI18n.project_custom_feature_id

curProj = -> APP.modules.project_page.curProj()

Template.justdo_i18n_project_config.helpers
  isModuleEnabled: ->
    return curProj().isCustomFeatureEnabled(module_id)

  pluginName: ->
    return JustdoI18n.plugin_human_readable_name

Template.justdo_i18n_project_config.events
  "click .project-conf-justdo-i18n-config": ->
    proj = curProj()

    if proj.isCustomFeatureEnabled(module_id)
      curProj().disableCustomFeatures(module_id)
    else
      curProj().enableCustomFeatures(module_id)
