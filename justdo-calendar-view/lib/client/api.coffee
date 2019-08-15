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
          return

        destroyer: =>
          APP.justdo_project_pane.unregisterTab "justdo_calendar"
          return

    @onDestroy =>
      custom_feature_maintainer.stop()

      return

    return