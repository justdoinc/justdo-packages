_.extend JustdoDependencies.prototype,
  registerConfigTemplate: ->
    APP.executeAfterAppClientCode ->
      module = APP.modules.project_page
      module.project_config_ui.registerConfigTemplate "justdo_dependencies_project_config",
        section: "extensions"
        template: "justdo_dependencies_project_config"
        priority: 100

    return

module_id = JustdoDependencies.project_custom_feature_id

curProj = -> APP.modules.project_page.curProj()

Template.justdo_dependencies_project_config.helpers
  isModuleEnabled: ->
    return curProj().isCustomFeatureEnabled(module_id)

  pluginName: ->
    return JustdoDependencies.plugin_human_readable_name

Template.justdo_dependencies_project_config.events
  "click .project-conf-justdo-dependencies-config": ->
    proj = curProj()

    if proj.isCustomFeatureEnabled(module_id)
      curProj().disableCustomFeatures(module_id)
    else
      curProj().enableCustomFeatures(module_id)
