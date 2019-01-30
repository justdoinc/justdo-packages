APP.executeAfterAppLibCode ->
  module = APP.modules.main

  module.user_config_ui.registerConfigTemplate "core-profile-settings",
    section: "profile"
    template: "core_user_conf_core_profile_settings"
    priority: 100

  module.user_config_ui.registerConfigTemplate "core-date-time-settings",
    section: "date_time_settings"
    template: "core_user_conf_core_time_settings"
    priority: 100
