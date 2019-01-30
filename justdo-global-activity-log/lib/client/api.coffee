_.extend JustdoGlobalActivityLog.prototype,
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
      APP.modules.project_page.setupProjectCustomFeatureOnProjectPage JustdoGlobalActivityLog.project_custom_feature_id,

      installer: =>
        @setupProjectPaneTab()

        return

      destroyer: =>
        @destroyProjectPaneTab()

        return

    @onDestroy =>
      custom_feature_maintainer.stop()

      return

    return

  setupProjectPaneTab: ->
    APP.justdo_project_pane.registerTab
      tab_id: "project-activity"
      order: 100
      tab_template: "global_activity_log_project_pane_project_activity_container"
      tab_label: "Activity"

    return

  destroyProjectPaneTab: ->
    APP.justdo_project_pane.unregisterTab "project-activity"

    return

  subscribeGlobalChangelog: (options) ->
    return Meteor.subscribe "jdGlobalChangelog", options
