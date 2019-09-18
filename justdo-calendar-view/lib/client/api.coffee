_.extend JustdoCalendarView.prototype,
  _immediateInit: ->
    @setupRouter()

    return

  _deferredInit: ->
    if @destroyed
      return

    @registerConfigTemplate()
    #@registerTaskPaneSection()
    @setupCustomFeatureMaintainer()

    return

  isPluginInstalledOnProjectDoc: (project_doc) ->
    return APP.projects.isPluginInstalledOnProjectDoc(JustdoTimeTracker.project_custom_feature_id, project_doc)

  setupCustomFeatureMaintainer: ->
    custom_feature_maintainer =
      APP.modules.project_page.setupProjectCustomFeatureOnProjectPage JustdoCalendarView.project_custom_feature_id,
        installer: =>
          APP.justdo_project_pane.registerTab
            tab_id: "justdo-calendar" #note - don't use _ in the name here
            order: 101
            tab_template: "justdo_calendar_project_pane"
            tab_label: "Calendar"

          APP.modules.project_page.setupPseudoCustomField JustdoCalendarView.end_date_field_id,
            label: JustdoCalendarView.end_date_field_label
            field_type: "date"
            grid_visible_column: true
            grid_editable_column: true
            default_width: 200

          return #installer

        destroyer: =>
          APP.justdo_project_pane.unregisterTab "justdo_calendar"
          APP.modules.project_page.removePseudoCustomFields JustdoCalendarView.end_date_field_id
          return #destroyer

    @onDestroy =>
      custom_feature_maintainer.stop()

      return

    return