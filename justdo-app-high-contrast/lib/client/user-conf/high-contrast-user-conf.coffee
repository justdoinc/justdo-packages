Template.justdo_user_config_high_contrast_config.helpers
  enabledForThisDevice: -> APP.justdo_app_high_contrast.isEnabledForThisDevice()

Template.justdo_user_config_high_contrast_config.events
  "click .justdo-user-config-high-contrast-config": ->
    APP.justdo_app_high_contrast.toggleHighContrastMode()

    return