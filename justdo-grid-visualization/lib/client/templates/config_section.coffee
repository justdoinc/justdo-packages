curProj = -> APP.modules.project_page.curProj()

module_id = "grid-visualization"

Template.grid_visualization_config.helpers
  isModuleEnabled: ->
    return APP.modules.project_page.curProj().isCustomFeatureEnabled(module_id)

Template.grid_visualization_config.events
  "click .project-conf-grid-visualization-config": ->
    proj = curProj()

    if proj.isCustomFeatureEnabled(module_id)
      curProj().disableCustomFeatures(module_id)
    else
      curProj().enableCustomFeatures(module_id)
