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
    @collection_hook = APP.collections.Tasks.before.update (user_id, doc, field_names, modifier, options) =>
      if APP.modules.project_page?.curProj()?.isAdmin()
        # Admins can edit
        return

      if ($set_modifier = modifier["$set"])?
        for field_id in @admin_only_fields
          if field_id of $set_modifier
            JustdoSnackbar.show
              text: "This field is editable only by admins"
              actionText: "Dismiss"
              onActionClick: => return

            return false

      return

  destroyer: ->
    @collection_hook.remove()

    return
