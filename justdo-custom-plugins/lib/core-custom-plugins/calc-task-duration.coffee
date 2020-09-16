APP.justdo_custom_plugins.installCustomPlugin
  # SETTINGS BEGIN
  #
  # The following properties should be defined by all custom plugins
  custom_plugin_id: "custom_justdo_calc_duration"

  custom_plugin_readable_name: "Task Duration Field"

  show_in_extensions_list: true
  #
  # / SETTINGS END

  calculated_duration_field_id: "custom:justdo:task_duration"
  calculated_duration_field_label: "Duration"

  installer: ->
    APP.modules.project_page.setupPseudoCustomField @calculated_duration_field_id,
      label: @calculated_duration_field_label
      field_type: "string"
      grid_visible_column: true
      grid_editable_column: false
      default_width: 200

    @collection_hook = APP.collections.Tasks.after.update (user_id, doc, field_names, modifier, options)=>
      if modifier["$set"]?["start_date"]? or modifier["$set"]?["start_date"] == null or
          modifier["$set"]?["end_date"]? or modifier["$set"]?["end_date"] == null or
          modifier.$set?[JustdoPlanningUtilities.is_milestone_pseudo_field_id]?
        
        new_val = ""
    
        if doc.start_date? and doc.end_date? and doc[JustdoPlanningUtilities.is_milestone_pseudo_field_id] != "true"
          from_date = moment(doc.start_date)
          to_date = moment(doc.end_date)
          diff_days = to_date.diff(from_date, "days") + 1

          if diff_days == 1
            new_val = "1 Day"
          else if diff_days <= 0
            new_val = "⚠️ End date < Start date"
          else
            new_val = "#{diff_days} Days"

        if new_val != doc[@calculated_duration_field_id]
          APP.collections.Tasks.update(doc._id, {$set: {"#{@calculated_duration_field_id}": new_val}})

      return

    return

  destroyer: ->
    APP.modules.project_page.removePseudoCustomFields @calculated_duration_field_id

    @collection_hook.remove()

    return
