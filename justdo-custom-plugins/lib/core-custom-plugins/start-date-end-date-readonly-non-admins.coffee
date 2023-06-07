APP.justdo_custom_plugins.installCustomPlugin
  # SETTINGS BEGIN
  #
  # The following properties should be defined by all custom plugins
  custom_plugin_id: "custom_start_date_end_date_readonly_non_admins"

  custom_plugin_readable_name: "Start Date/End Date Editable by Admins Only"

  show_in_extensions_list: false
  #
  # / SETTINGS END

  admin_only_fields: ["start_date", "end_date"]

  installer: ->
    #
    # Lock Gantt dates edits
    #
    grid_gantt_locked = false
    unlockGanttDatesEdit = =>
      if not grid_gantt_locked
        # Already unlocked
        return

      grid_gantt_locked = false # We need that flag because a user might stop being a non-admin during a session.
      APP.justdo_planning_utilities?.unlockDatesEdit()

      return

    lockGanttDatesEdit = =>
      if grid_gantt_locked
        # Already locked
        return

      grid_gantt_locked = true # We need that flag because a user might stop being a non-admin during a session.
      APP.justdo_planning_utilities?.lockDatesEdit()

      return

    @is_admin_computation = Tracker.autorun =>
      # Doesn't matter if the gantt is enabled or not, if user will enable it during the session
      # things will be set correctly
      if APP.modules.project_page.curProj().isAdmin()
        unlockGanttDatesEdit()
      else
        lockGanttDatesEdit()

      Tracker.onInvalidate =>

        unlockGanttDatesEdit()

        return

      return

    #
    # Lock admin_only_fields hooks
    #
    @collection_hook = APP.collections.Tasks.before.update (user_id, doc, field_names, modifier, options) =>
      if APP.modules.project_page?.curProj()?.isAdmin()
        # Admins can edit
        return

      if ($set_modifier = modifier["$set"])?
        for field_id in @admin_only_fields
          if field_id of $set_modifier
            JustdoSnackbar.show
              text: "This field is editable only by admins"

            return false

      return

  destroyer: ->
    @is_admin_computation.stop()

    @collection_hook.remove()

    return
