_.extend JustdoRowsStyling.prototype,
  registerConfigTemplate: ->
    APP.executeAfterAppClientCode ->
      module = APP.modules.project_page
      module.project_config_ui.registerConfigTemplate "justdo_rows_styling_project_config",
        section: "extensions"
        template: "justdo_rows_styling_project_config"
        priority: 1000

    return

module_id = JustdoRowsStyling.project_custom_feature_id

curProj = -> APP.modules.project_page.curProj()

Template.justdo_rows_styling_project_config.helpers
  isModuleEnabled: ->
    return APP.modules.project_page.curProj().isCustomFeatureEnabled(module_id)

Template.justdo_rows_styling_project_config.events
  "click .project-conf-justdo-rows-styling-config": ->
    proj = curProj()

    if proj.isCustomFeatureEnabled(module_id)
      proj.disableCustomFeatures(module_id)
    else
      proj.enableCustomFeatures(module_id)

