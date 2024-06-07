_.extend JustdoI18nRoutes.prototype,
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
      APP.modules.project_page.setupProjectCustomFeatureOnProjectPage JustdoI18nRoutes.project_custom_feature_id,
        installer: =>
          if JustdoI18nRoutes.add_pseudo_field
            APP.modules.project_page.setupPseudoCustomField JustdoI18nRoutes.pseudo_field_id,
              label: JustdoI18nRoutes.pseudo_field_label
              field_type: JustdoI18nRoutes.pseudo_field_type
              grid_visible_column: true
              grid_editable_column: true
              default_width: 200

          return

        destroyer: =>
          if JustdoI18nRoutes.add_pseudo_field
            APP.modules.project_page.removePseudoCustomFields JustdoI18nRoutes.pseudo_field_id

          return

    @onDestroy =>
      custom_feature_maintainer.stop()

      return

    return
