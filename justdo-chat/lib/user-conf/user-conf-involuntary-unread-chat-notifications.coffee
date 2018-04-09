APP.executeAfterAppLibCode ->
  module = APP.modules.main

  module.user_config_ui.registerConfigSection "justdo-chat",
    # Add to this section the configs that you want to show first,
    # without any specific title (usually very basic configurations)

    title: "Chat" # null means no title
    priority: 200

  module.user_config_ui.registerConfigTemplate "involuntary-unread-email-notifications",
    section: "justdo-chat"
    template: "involuntary_unread_email_chat_notifications_subscription_profile_settings"
    priority: 100
