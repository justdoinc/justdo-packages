_.extend JustdoProjectsDashboard.prototype,
  _immediateInit: ->
    return

  _deferredInit: ->
    if @destroyed
      return

    @registerConfigTemplate()
    @setupCustomFeatureMaintainer()

    return

  setupCustomFeatureMaintainer: ->
    custom_feature_maintainer =
      APP.modules.project_page.setupProjectCustomFeatureOnProjectPage JustdoProjectsDashboard.project_custom_feature_id,
        installer: =>
          APP.justdo_project_pane.registerTab
            tab_id: "justdo-projects-dashboard"
            order: 1
            tab_template: "justdo_projects_dashboard"
            tab_label: "Dashboard"
          return

        destroyer: =>
          return

    @onDestroy =>
      custom_feature_maintainer.stop()
      return
    return
