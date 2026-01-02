_.extend JustdoMcp.prototype,
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
      APP.modules.project_page.setupProjectCustomFeatureOnProjectPage JustdoMcp.project_custom_feature_id,
        installer: =>
          if JustdoMcp.add_pseudo_field
            APP.modules.project_page.setupPseudoCustomField JustdoMcp.pseudo_field_id,
              label: JustdoMcp.pseudo_field_label
              field_type: JustdoMcp.pseudo_field_type
              grid_visible_column: true
              grid_editable_column: true
              default_width: 200

          return

        destroyer: =>
          if JustdoMcp.add_pseudo_field
            APP.modules.project_page.removePseudoCustomFields JustdoMcp.pseudo_field_id

          return

    @onDestroy =>
      custom_feature_maintainer.stop()

      return

    return
