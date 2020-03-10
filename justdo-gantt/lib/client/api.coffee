_.extend JustdoGantt.prototype,
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
      APP.modules.project_page.setupProjectCustomFeatureOnProjectPage JustdoGantt.project_custom_feature_id,
        installer: =>
          APP.justdo_project_pane.registerTab
            tab_id: "justdo-gantt"
            order: 103
            tab_template: "justdo_gantt"
            tab_label: "Gantt Chart"
          APP.justdo_resources_availability.enableResourceAvailability JustdoGantt.project_custom_feature_id
          return

        destroyer: =>
          APP.justdo_project_pane.unregisterTab "justdo-gantt"
          APP.justdo_resources_availability.disbleResourceAvailability JustdoGantt.project_custom_feature_id
          return

    @onDestroy =>
      custom_feature_maintainer.stop()

      return

    return
