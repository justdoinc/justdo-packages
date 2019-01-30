_.extend JustdoDeliveryPlanner.prototype,
  registerConfigTemplate: ->
    APP.executeAfterAppClientCode ->
      module = APP.modules.project_page
      module.project_config_ui.registerConfigTemplate "justdo_delivery_planner_project_config",
        section: "extensions"
        template: "justdo_delivery_planner_project_config"
        priority: 100

    return

module_id = JustdoDeliveryPlanner.project_custom_feature_id

curProj = -> APP.modules.project_page.curProj()

Template.justdo_delivery_planner_project_config.helpers
  isModuleEnabled: ->
    return curProj().isCustomFeatureEnabled(module_id)

Template.justdo_delivery_planner_project_config.events
  "click .project-conf-justdo-delivery-planner-config": ->
    proj = curProj()

    if proj.isCustomFeatureEnabled(module_id)
      curProj().disableCustomFeatures(module_id)
    else
      curProj().enableCustomFeatures(module_id)

