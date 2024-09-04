APP.executeAfterAppLibCode ->
  main_module = APP.modules.main

  main_module.user_config_ui.registerConfigSection "basic",
    # Add to this section the configs that you want to show first,
    # without any specific title (usually very basic configurations)

    title: null # null means no title
    priority: 10

  main_module.user_config_ui.registerConfigSection "profile",
    title: null
    priority: 10

  main_module.user_config_ui.registerConfigSection "date_time_settings",
    title: "core_user_conf_date_time_title"
    priority: 100

  main_module.user_config_ui.registerConfigSection "email_notifications_settings",
    title: "core_user_conf_email_notifications_title"
    priority: 100

  main_module.user_config_ui.registerConfigSection "appearance",
    title: "core_user_conf_appereance_title"
    priority: 100

  main_module.user_config_ui.registerConfigSection "extensions",
    title: "core_user_conf_extensions_title"
    priority: 200
