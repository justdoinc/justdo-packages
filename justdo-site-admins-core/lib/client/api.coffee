_.extend JustdoSiteAdminsCore.prototype,
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
      APP.modules.project_page.setupProjectCustomFeatureOnProjectPage JustdoSiteAdminsCore.project_custom_feature_id,
        installer: =>
          if JustdoSiteAdminsCore.add_pseudo_field
            APP.modules.project_page.setupPseudoCustomField JustdoSiteAdminsCore.pseudo_field_id,
              label: JustdoSiteAdminsCore.pseudo_field_label
              field_type: JustdoSiteAdminsCore.pseudo_field_type
              grid_visible_column: true
              grid_editable_column: true
              default_width: 200

          return

        destroyer: =>
          if JustdoSiteAdminsCore.add_pseudo_field
            APP.modules.project_page.removePseudoCustomFields JustdoSiteAdminsCore.pseudo_field_id

          return

    @onDestroy =>
      custom_feature_maintainer.stop()

      return

    return
