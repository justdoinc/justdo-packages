APP.justdo_custom_plugins.installCustomPlugin
  # SETTINGS BEGIN
  #
  # The following properties should be defined by all custom plugins
  custom_plugin_id: JustdoCustomPlugins.justdo_task_duration_custom_feature_id

  custom_plugin_readable_name: JustdoCustomPlugins.justdo_task_duration_custom_feature_label

  show_in_extensions_list: true
  #
  # / SETTINGS END

  justdo_task_duration_field_label: "Duration"

  installer: ->
    self = @

    APP.modules.project_page.setupPseudoCustomField JustdoCustomPlugins.justdo_task_duration_pseudo_field_id,
      label: JustdoCustomPlugins.justdo_task_duration_pseudo_field_label
      field_type: "number"
      formatter: JustdoCustomPlugins.justdo_task_duration_pseudo_field_formatter_id
      grid_visible_column: true
      grid_editable_column: true
      default_width: 100

    APP.justdo_resources_availability.enableResourceAvailability JustdoCustomPlugins.justdo_task_duration_custom_feature_id

    # Catching changes of start_date, end_date, duration of tasks
    self.collection_hook = APP.collections.Tasks.before.update (user_id, doc, field_names, modifier, options) ->
      if ((new_start_date = modifier?.$set?.start_date) isnt undefined or
          (new_end_date = modifier?.$set?.end_date) isnt undefined or
          (new_duration = modifier?.$set?[JustdoCustomPlugins.justdo_task_duration_pseudo_field_id]) isnt undefined) and
          APP.justdo_custom_plugins.justdo_task_duration.isPluginInstalled doc.project_id
        changes = APP.justdo_custom_plugins.justdo_task_duration.recalculateDatesAndDuration doc._id, modifier.$set
        if changes?
          _.extend modifier.$set, changes
      
      return

    return

  destroyer: ->
    self = @
    
    self.collection_hook.remove()

    APP.justdo_resources_availability.disbleResourceAvailability JustdoCustomPlugins.justdo_task_duration_custom_feature_id

    APP.modules.project_page.removePseudoCustomFields JustdoCustomPlugins.justdo_task_duration_pseudo_field_id

    # @collection_hook.remove()

    return
