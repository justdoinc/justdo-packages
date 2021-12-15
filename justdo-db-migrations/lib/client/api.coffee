_.extend JustdoDbMigrations.prototype,
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
      APP.modules.project_page.setupProjectCustomFeatureOnProjectPage JustdoDbMigrations.project_custom_feature_id,
        installer: =>
          if JustdoDbMigrations.add_pseudo_field
            APP.modules.project_page.setupPseudoCustomField JustdoDbMigrations.pseudo_field_id,
              label: JustdoDbMigrations.pseudo_field_label
              field_type: JustdoDbMigrations.pseudo_field_type
              grid_visible_column: true
              grid_editable_column: true
              default_width: 200

          return

        destroyer: =>
          if JustdoDbMigrations.add_pseudo_field
            APP.modules.project_page.removePseudoCustomFields JustdoDbMigrations.pseudo_field_id

          return

    @onDestroy =>
      custom_feature_maintainer.stop()

      return

    return
