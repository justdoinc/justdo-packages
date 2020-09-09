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

    # APP.justdo_resources_availability.enableResourceAvailability JustdoCustomPlugins.justdo_task_duration_custom_feature_id

    return

  destroyer: ->
    # APP.justdo_resources_availability.disbleResourceAvailability JustdoCustomPlugins.justdo_task_duration_custom_feature_id

    APP.modules.project_page.removePseudoCustomFields JustdoCustomPlugins.justdo_task_duration_pseudo_field_id

    # @collection_hook.remove()

    return
