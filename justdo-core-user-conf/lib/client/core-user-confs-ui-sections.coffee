APP.executeAfterAppLibCode ->
  module = APP.modules.main

  module.user_config_ui.registerConfigSection "basic",
    # Add to this section the configs that you want to show first,
    # without any specific title (usually very basic configurations)

    title: null # null means no title
    priority: 10

  module.user_config_ui.registerConfigSection "profile",
    title: null
    priority: 10

  module.user_config_ui.registerConfigSection "date_time_settings",
    title: "Date & Time"
    priority: 100

  module.user_config_ui.registerConfigSection "email_notifications_settings",
    title: "Email Notifications"
    priority: 100

  module.user_config_ui.registerConfigSection "appearance",
    title: "Appearance"
    priority: 100

  module.user_config_ui.registerConfigSection "extensions",
    title: "Extensions"
    priority: 200
