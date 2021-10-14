Template.justdo_system_updates_config.helpers
  enabled: -> APP.justdo_system_updates.isEnabledForLoggedInUser()

Template.justdo_system_updates_config.events
  "click .justdo-system-updates-config": (e, tpl) ->
    APP.justdo_system_updates.toggleDisplayOption()

    return
