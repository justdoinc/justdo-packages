Template.create_new_justdo_with_same_settings.helpers
  createNewJustdoWithSameSettingsEnabled: ->
    return APP.modules.project_page.curProj().isCustomFeatureEnabled("create-new-justdo-with-same-settings")

Template.create_new_justdo_with_same_settings.events
  "click .create-justdo-same-settings": ->
    APP.projects.createNewJustdoWithSameSettings()
    bootbox.hideAll()
    return