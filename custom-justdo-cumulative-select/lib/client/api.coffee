_.extend CustomJustdoCumulativeSelect.prototype,
  _immediateInit: ->
    return

  _deferredInit: ->
    if @destroyed
      return

    @registerConfigTemplate()
    @setupCustomFeatureMaintainer()

    return

  isPluginInstalledOnProjectDoc: (project_doc) ->
    return APP.projects.isPluginInstalledOnProjectDoc(CustomJustdoCumulativeSelect.project_custom_feature_id, project_doc)

  setupCustomFeatureMaintainer: ->
    custom_feature_maintainer =
      APP.modules.project_page.setupProjectCustomFeatureOnProjectPage CustomJustdoCumulativeSelect.project_custom_feature_id,
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