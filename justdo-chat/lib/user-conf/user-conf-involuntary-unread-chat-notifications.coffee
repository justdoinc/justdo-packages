APP.executeAfterAppLibCode ->
  main_module = APP.modules.main

  main_module.user_config_ui.registerConfigTemplate "involuntary-unread-email-notifications",
    section: "justdo-emails"
    template: "involuntary_unread_email_chat_notifications_subscription_profile_settings"
    priority: 200
