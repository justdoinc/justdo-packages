APP.executeAfterAppLibCode ->
  main_module = APP.modules.main

  main_module.user_config_ui.registerConfigSection "justdo-emails",
    # Add to this section the configs that you want to show first,
    # without any specific title (usually very basic configurations)

    title: "email_config_title" # null means no title
    priority: 200

  main_module.user_config_ui.registerConfigTemplate "unsubscribe-from-all-emails-toggle",
    section: "justdo-emails"
    template: "justdo_emails_unsubscribe_from_all_emails_toggle"
    priority: 100
