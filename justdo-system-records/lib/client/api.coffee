_.extend JustdoSystemRecords.prototype,
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
      APP.modules.project_page.setupProjectCustomFeatureOnProjectPage JustdoSystemRecords.project_custom_feature_id,
        installer: =>
          if JustdoSystemRecords.add_pseudo_field
            APP.modules.project_page.setupPseudoCustomField JustdoSystemRecords.pseudo_field_id,
              label: JustdoSystemRecords.pseudo_field_label
              field_type: JustdoSystemRecords.pseudo_field_type
              grid_visible_column: true
              grid_editable_column: true
              default_width: 200

          return

        destroyer: =>
          if JustdoSystemRecords.add_pseudo_field
            APP.modules.project_page.removePseudoCustomFields JustdoSystemRecords.pseudo_field_id

          return

    @onDestroy =>
      custom_feature_maintainer.stop()

      return

    return
