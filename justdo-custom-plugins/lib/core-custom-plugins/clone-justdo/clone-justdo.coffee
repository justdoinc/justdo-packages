custom_plugin_id = "clone_justdo"

APP.justdo_custom_plugins.installCustomPlugin
  # SETTINGS BEGIN
  #
  # The following properties should be defined by all custom plugins
  custom_plugin_id: custom_plugin_id

  custom_plugin_readable_name: "Clone JustDo"

  show_in_extensions_list: true
  # / SETTINGS END

  installer: ->
    APP.modules.project_page.project_config_ui.registerConfigTemplate "create-new-justdo-with-same-settings",
      section: "operations"
      template: "create_new_justdo_with_same_settings"
      priority: 10001
      
    return

  destroyer: ->
    APP.modules.project_page.project_config_ui.unregisterConfigTemplate "operations", "create-new-justdo-with-same-settings"

    return

Template.create_new_justdo_with_same_settings.events
  "click .create-justdo-same-settings": ->
    APP.projects.createNewJustdoWithSameSettings()
    bootbox.hideAll()
    return