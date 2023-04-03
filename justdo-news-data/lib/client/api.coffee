_.extend JustdoNewsData.prototype,
  _immediateInit: ->
    @setupRouter()

    return

  _deferredInit: ->
    if @destroyed
      return

    @registerConfigTemplate()
    @registerTaskPaneSection()
    @setupCustomFeatureMaintainer()

    return

  isPluginInstalledOnProjectDoc: (project_doc) ->
    return APP.projects.isPluginInstalledOnProjectDoc(JustdoNewsData.project_custom_feature_id, project_doc)

  getProjectDocIfPluginInstalled: (project_id) ->
    return @projects_collection.findOne({_id: project_id, "conf.custom_features": JustdoNewsData.project_custom_feature_id})

  setupCustomFeatureMaintainer: ->
    custom_feature_maintainer =
      APP.modules.project_page.setupProjectCustomFeatureOnProjectPage JustdoNewsData.project_custom_feature_id,
        installer: =>
          if JustdoNewsData.add_pseudo_field
            APP.modules.project_page.setupPseudoCustomField JustdoNewsData.pseudo_field_id,
              label: JustdoNewsData.pseudo_field_label
              field_type: JustdoNewsData.pseudo_field_type
              grid_visible_column: true
              grid_editable_column: true
              default_width: 200

          return

        destroyer: =>
          if JustdoNewsData.add_pseudo_field
            APP.modules.project_page.removePseudoCustomFields JustdoNewsData.pseudo_field_id

          return

    @onDestroy =>
      custom_feature_maintainer.stop()

      return

    return