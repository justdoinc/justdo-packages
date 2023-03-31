_.extend JustdoNews.prototype,
  registerConfigTemplate: ->
    APP.executeAfterAppClientCode ->
      module = APP.modules.project_page
      module.project_config_ui.registerConfigTemplate "justdo_news_project_config",
        section: "extensions"
        template: "justdo_news_project_config"
        priority: 100

    return

module_id = JustdoNews.project_custom_feature_id

curProj = -> APP.modules.project_page.curProj()

Template.justdo_news_project_config.helpers
  isModuleEnabled: ->
    return curProj().isCustomFeatureEnabled(module_id)

  pluginName: ->
    return JustdoNews.plugin_human_readable_name

Template.justdo_news_project_config.events
  "click .project-conf-justdo-news-config": ->
    proj = curProj()

    if proj.isCustomFeatureEnabled(module_id)
      curProj().disableCustomFeatures(module_id)
    else
      curProj().enableCustomFeatures(module_id)
