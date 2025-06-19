project_page_module = APP.modules.project_page
curProj = -> APP.modules.project_page.curProj()

Template.projects_collection_project_config.helpers
  pluginName: ->
    return TAPi18n.__ JustdoDeliveryPlanner.projects_collection_plugin_name_i18n

  isModuleEnabled: ->
    return APP.justdo_delivery_planner.isProjectsCollectionEnabledOnProjectId(JD.activeJustdoId())

Template.projects_collection_project_config.events
    "click .project-conf-projects-collection-config": ->
      proj = curProj()

      if APP.justdo_delivery_planner.isProjectsCollectionEnabledOnProjectId(JD.activeJustdoId())
        curProj().disableCustomFeatures(JustdoDeliveryPlanner.projects_collection_plugin_id)
      else
        curProj().enableCustomFeatures(JustdoDeliveryPlanner.projects_collection_plugin_id)

      return
