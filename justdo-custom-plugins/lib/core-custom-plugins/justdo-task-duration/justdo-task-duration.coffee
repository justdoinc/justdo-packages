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
    APP.modules.project_page.setupPseudoCustomField JustdoCustomPlugins.justdo_task_duration_pseudo_field_id,
      label: JustdoCustomPlugins.justdo_task_duration_pseudo_field_label
      field_type: "number"
      formatter: JustdoCustomPlugins.justdo_task_duration_pseudo_field_formatter_id
      grid_visible_column: true
      grid_editable_column: true
      default_width: 100

    APP.justdo_resources_availability.enableResourceAvailability JustdoCustomPlugins.justdo_task_duration_custom_feature_id
    
    # Recalcuate duration of all tasks with start_date and end_date
    Tracker.nonreactive ->
      active_justdo = JD.activeJustdo
        _id: 1
        conf: 1

      is_grid_gantt_enabled = APP.justdo_grid_gantt.isPluginInstalledOnProjectDoc active_justdo

      APP.collections.Tasks.find
        project_id: active_justdo._id
      ,
        fields:
          _id: 1
          start_date: 1
          end_date: 1
          pending_owner_id: 1
          owner_id: 1
          "#{JustdoCustomPlugins.justdo_task_duration_pseudo_field_id}": 1
          "#{JustdoGridGantt.is_milestone_pseudo_field_id}": 1
      .forEach (task) ->
        owner_id = task.pending_owner_id or task.owner_id
        if not task.start_date? or not task.end_date? or
            is_grid_gantt_enabled and task[JustdoGridGantt.is_milestone_pseudo_field_id] == "true"
          working_days = null
        else
          {working_days, avail_hrs} = APP.justdo_resources_availability.userAvailabilityBetweenDates task.start_date, task.end_date, active_justdo._id, owner_id

        if not task[JustdoCustomPlugins.justdo_task_duration_pseudo_field_id]? and working_days == null or
            task[JustdoCustomPlugins.justdo_task_duration_pseudo_field_id] == working_days
          return

        APP.collections.Tasks.update task._id,
          $set:
            "#{JustdoCustomPlugins.justdo_task_duration_pseudo_field_id}": working_days

      return

    # @collection_hook = APP.collections.Tasks.after.update (user_id, doc, field_names, modifier, options) =>

    #   return

    return

  destroyer: ->
    APP.justdo_resources_availability.disbleResourceAvailability JustdoCustomPlugins.justdo_task_duration_custom_feature_id

    APP.modules.project_page.removePseudoCustomFields JustdoCustomPlugins.justdo_task_duration_pseudo_field_id

    # @collection_hook.remove()

    return
