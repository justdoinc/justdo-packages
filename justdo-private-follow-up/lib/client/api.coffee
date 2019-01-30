_.extend JustdoPrivateFollowUp.prototype,
  _immediateInit: ->
    return

  _deferredInit: ->
    if @destroyed
      return

    @registerConfigTemplate()
    @setupCustomFeatureMaintainer()

    return

  pluginEnabledForActiveProject: ->
    project_obj = APP.modules.project_page.curProj()

    if not project_obj?
      return false

    return project_obj.isCustomFeatureEnabled(JustdoPrivateFollowUp.project_custom_feature_id)

  setupCustomFeatureMaintainer: ->
    custom_feature_maintainer =
      APP.modules.project_page.setupProjectCustomFeatureOnProjectPage JustdoPrivateFollowUp.project_custom_feature_id,

        installer: =>
          APP.modules.project_page.setupPseudoCustomField JustdoPrivateFollowUp.private_follow_up_field_id,
            label: JustdoPrivateFollowUp.private_follow_up_field_label
            field_type: "date"
            grid_visible_column: true
            formatter: "unicodeDatePrivateFollowUpDateFormatter"
            grid_editable_column: true
            editor: "UnicodeDatePrivateFollowUpDateEditor"
            default_width: 200
            filter_options: APP?.collections?.Tasks?.simpleSchema()?._schema?["follow_up"]?.grid_column_filter_settings?.options

          return

        destroyer: =>
          APP.modules.project_page.removePseudoCustomFields JustdoPrivateFollowUp.private_follow_up_field_id

          return

    @onDestroy =>
      custom_feature_maintainer.stop()

      return

    return
