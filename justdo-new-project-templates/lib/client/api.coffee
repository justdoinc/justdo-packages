_.extend JustdoNewProjectTemplates.prototype,
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
      APP.modules.project_page.setupProjectCustomFeatureOnProjectPage JustdoNewProjectTemplates.project_custom_feature_id,
        installer: =>
          if JustdoNewProjectTemplates.add_pseudo_field
            APP.modules.project_page.setupPseudoCustomField JustdoNewProjectTemplates.pseudo_field_id,
              label: JustdoNewProjectTemplates.pseudo_field_label
              field_type: JustdoNewProjectTemplates.pseudo_field_type
              grid_visible_column: true
              grid_editable_column: true
              default_width: 200

          return

        destroyer: =>
          if JustdoNewProjectTemplates.add_pseudo_field
            APP.modules.project_page.removePseudoCustomFields JustdoNewProjectTemplates.pseudo_field_id

          return

    @onDestroy =>
      custom_feature_maintainer.stop()

      return

    return
