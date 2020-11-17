_.extend JustdoCalendarView.prototype,
  registerConfigTemplate: ->
    APP.executeAfterAppClientCode ->
      module = APP.modules.project_page
      module.project_config_ui.registerConfigTemplate "justdo_calendar_view_project_config",
        section: "extensions"
        template: "justdo_calendar_view_project_config"
        priority: 600

      return

    return

module_id = JustdoCalendarView.project_custom_feature_id

curProj = -> APP.modules.project_page.curProj()

Template.justdo_calendar_view_project_config.helpers
  isModuleEnabled: ->
    return curProj().isCustomFeatureEnabled(module_id)

  pluginName: ->
    return JustdoCalendarView.plugin_human_readable_name

Template.justdo_calendar_view_project_config.events
  "click .project-conf-justdo-calendar-view-config": ->
    proj = curProj()

    if proj.isCustomFeatureEnabled(module_id)
      curProj().disableCustomFeatures(module_id)
    else
      curProj().enableCustomFeatures(module_id)

    return
