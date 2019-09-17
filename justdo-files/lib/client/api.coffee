_.extend JustdoFiles.prototype,
  _immediateInit: ->
    return

  _deferredInit: ->
    if @destroyed
      return

    @registerConfigTemplate()
    @registerTaskPaneSection()
    @setupCustomFeatureMaintainer()

    return

  setupCustomFeatureMaintainer: ->
    custom_feature_maintainer =
      APP.modules.project_page.setupProjectCustomFeatureOnProjectPage JustdoFiles.project_custom_feature_id,
        installer: =>
          console.log "HERE INSTALLER"

          return

        destroyer: =>
          console.log "HERE DESTROYER"

          return

    @onDestroy =>
      custom_feature_maintainer.stop()

      return

    return
