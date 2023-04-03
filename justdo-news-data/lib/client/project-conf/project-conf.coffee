_.extend JustdoNewsData.prototype,
  registerConfigTemplate: ->
    APP.executeAfterAppClientCode ->
      module = APP.modules.project_page
      module.project_config_ui.registerConfigTemplate "justdo_news_data_project_config",
        section: "extensions"
        template: "justdo_news_data_project_config"
        priority: 100

    return

module_id = JustdoNewsData.project_custom_feature_id

curProj = -> APP.modules.project_page.curProj()

Template.justdo_news_data_project_config.helpers
  isModuleEnabled: ->
    return curProj().isCustomFeatureEnabled(module_id)

  pluginName: ->
    return JustdoNewsData.plugin_human_readable_name

Template.justdo_news_data_project_config.events
  "click .project-conf-justdo-news-data-config": ->
    proj = curProj()

    if proj.isCustomFeatureEnabled(module_id)
      proj.disableCustomFeatures(module_id)
    else
      proj.enableCustomFeatures(module_id)

    return