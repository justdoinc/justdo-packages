_.extend JustdoQuickNotes.prototype,
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
      APP.modules.project_page.setupProjectCustomFeatureOnProjectPage JustdoQuickNotes.project_custom_feature_id,
        installer: =>
          return

        destroyer: =>
          return

    @onDestroy =>
      custom_feature_maintainer.stop()

      return

    return
