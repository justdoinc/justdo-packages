_.extend JustdoGridViews.prototype,
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
      APP.modules.project_page.setupProjectCustomFeatureOnProjectPage JustdoGridViews.project_custom_feature_id,
        installer: =>
          if JustdoGridViews.add_pseudo_field
            APP.modules.project_page.setupPseudoCustomField JustdoGridViews.pseudo_field_id,
              label: JustdoGridViews.pseudo_field_label
              field_type: JustdoGridViews.pseudo_field_type
              grid_visible_column: true
              grid_editable_column: true
              default_width: 200

          return

        destroyer: =>
          if JustdoGridViews.add_pseudo_field
            APP.modules.project_page.removePseudoCustomFields JustdoGridViews.pseudo_field_id

          return

    @onDestroy =>
      custom_feature_maintainer.stop()

      return

    return
