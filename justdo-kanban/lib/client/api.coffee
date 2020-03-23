_.extend JustdoKanban.prototype,
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
      APP.modules.project_page.setupProjectCustomFeatureOnProjectPage JustdoKanban.project_custom_feature_id,
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
      tab_id: "kanban"
      order: 100
      tab_template: "project_pane_kanban"
      tab_label: "Kanban"

    return

  destroyProjectPaneTab: ->
    APP.justdo_project_pane.unregisterTab "kanban"

    return

  subscribeToKanbans: (task_id) ->
    return Meteor.subscribe "kanbans", task_id
