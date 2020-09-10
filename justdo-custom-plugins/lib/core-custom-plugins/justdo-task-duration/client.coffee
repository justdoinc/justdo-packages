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

    # Catching changes of start_date, end_date, duration, is_milestone of tasks
    self.collection_hook = APP.collections.Tasks.before.update (user_id, doc, field_names, modifier, options) ->
      # XXX This is a redundant piece of code to solve the racing condition of the hooks, should be removed after refactor
      if doc[JustdoGridGantt.is_milestone_pseudo_field_id] == "true" and
          modifier?.$set?.start_date is undefined and 
          modifier?.$set?.end_date isnt undefined
        JustdoSnackbar.show
          text: "The end_date will always be the same as the start_date because it is a milestone."
        return false

      if (modifier?.$set?.start_date isnt undefined or
          modifier?.$set?.end_date isnt undefined or
          modifier?.$set?[JustdoCustomPlugins.justdo_task_duration_pseudo_field_id] isnt undefined or
          modifier?.$set?[JustdoGridGantt.is_milestone_pseudo_field_id] isnt undefined) and
          APP.justdo_custom_plugins.justdo_task_duration.isPluginInstalled doc.project_id
        set_values = APP.justdo_custom_plugins.justdo_task_duration.recalculateDatesAndDuration doc._id, modifier.$set
        if set_values?
          _.extend modifier.$set, set_values
        
        is_changed = false
        for field, val of modifier.$set
          if doc[field] != val
            is_changed = true
            break
        
        if not is_changed
          return false

      return true
    
    return

  destroyer: ->
    self = @

    self.collection_hook.remove()

    APP.justdo_resources_availability.disbleResourceAvailability JustdoCustomPlugins.justdo_task_duration_custom_feature_id

    APP.modules.project_page.removePseudoCustomFields JustdoCustomPlugins.justdo_task_duration_pseudo_field_id

    return
