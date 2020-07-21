APP.justdo_custom_plugins.installCustomPlugin
  # SETTINGS BEGIN
  #
  # The following properties should be defined by all custom plugins
  custom_plugin_id: "custom_justdo_merge"

  custom_plugin_readable_name: "Merge JustDos"

  show_in_extensions_list: true
  #
  # / SETTINGS END

  calculated_duration_field_id: "custom:justdo:task_duration"
  calculated_duration_field_label: "Duration"

  installer: ->
    # Add a button FOR ADMINS ONLY next to the Cog icon -> Merge JustDos simple dialog
    # that allows the user to choose one of the APP.collections.Projects.find() justdos
    # to merge to.
    #
    # A button MERGE , must ensure with alert the user want to proceed
    #
    # Once the method returns take the user to the new JustDo.
    #
    # Remove the old one by calling:
    # Meteor.call "removeProject", old_justdo_id, (err) ->
    #   cb(err)
    #   return

    return

  destroyer: ->
    # Remember to write proper destroyer


    return
