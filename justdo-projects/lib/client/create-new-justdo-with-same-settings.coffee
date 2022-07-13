Template.create_new_justdo_with_same_settings.events
  "click .create-justdo-same-settings": ->
    APP.projects.createNewJustdoWithSameSettings()
    bootbox.hideAll()
    return