_.extend JustdoResourcesAvailability.prototype,
  registerConfigTemplate: ->
    APP.executeAfterAppClientCode ->
      module = APP.modules.project_page
      module.project_config_ui.registerConfigTemplate "justdo_resources_availability_project_config",
        section: "extensions"
        template: "justdo_resources_availability_project_config"
        priority: 100

    return

module_id = JustdoResourcesAvailability.project_custom_feature_id

curProj = -> APP.modules.project_page.curProj()

Template.justdo_resources_availability_project_config.helpers
  isModuleEnabled: ->
    return curProj().isCustomFeatureEnabled(module_id)

  pluginName: ->
    return JustdoResourcesAvailability.plugin_human_readable_name

Template.justdo_resources_availability_project_config.events
  "click .project-conf-justdo-resources-availability-config": ->
    proj = curProj()

    if proj.isCustomFeatureEnabled(module_id)
      curProj().disableCustomFeatures(module_id)
    else
      curProj().enableCustomFeatures(module_id)

  "click .resources-availability-config-justdo-level": ->
    APP.justdo_resources_availability.displayConfigDialog(JD.activeJustdo({_id: 1})._id)
    return
