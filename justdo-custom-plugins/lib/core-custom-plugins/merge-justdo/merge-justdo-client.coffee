APP.justdo_custom_plugins.installCustomPlugin
  # SETTINGS BEGIN
  #
  # The following properties should be defined by all custom plugins
  custom_plugin_id: "custom_justdo_merge"

  custom_plugin_readable_name: "Merge JustDo"

  show_in_extensions_list: true
  # / SETTINGS END

  installer: ->
    JD.registerPlaceholderItem "merge-justdo", 
      domain: "settings-dropdown-bottom"
      listingCondition: -> JD.active_justdo.isAdmin()
      data:
        template: "merge_justdo_cog_button"

    return

  destroyer: ->
    JD.unregisterPlaceholderItem "merge-justdo"
    return
