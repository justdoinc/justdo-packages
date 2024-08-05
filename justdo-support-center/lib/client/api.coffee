_.extend JustdoSupportCenter.prototype,
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
      APP.modules.project_page.setupProjectCustomFeatureOnProjectPage JustdoSupportCenter.project_custom_feature_id,
        installer: =>
          if JustdoSupportCenter.add_pseudo_field
            APP.modules.project_page.setupPseudoCustomField JustdoSupportCenter.pseudo_field_id,
              label: JustdoSupportCenter.pseudo_field_label
              field_type: JustdoSupportCenter.pseudo_field_type
              grid_visible_column: true
              grid_editable_column: true
              default_width: 200

          return

        destroyer: =>
          if JustdoSupportCenter.add_pseudo_field
            APP.modules.project_page.removePseudoCustomFields JustdoSupportCenter.pseudo_field_id

          return

    @onDestroy =>
      custom_feature_maintainer.stop()

      return

    return
