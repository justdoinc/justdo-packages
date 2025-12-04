JustdoEmails = {}

_.extend JustdoEmails,
  user_preference_subdocument_id: "justdo_emails"

_.extend JustdoEmails,
  registrar: JustdoHelpers.createNotificationRegistrar
    user_preference_subdocument_id: JustdoEmails.user_preference_subdocument_id
    label_i18n: "receive_email_notifications"
    user_config_options:
      _id: "justdo-emails"
      priority: 200
    custom_options_schema: new SimpleSchema
      hide_footer:
        type: Boolean
        optional: true
        defaultValue: false
      hide_unsubscribe_links:
        type: Boolean
        optional: true
        defaultValue: false
      send_to_proxy_users:
        type: Boolean
        optional: true
        defaultValue: false
  
  registerEmailCategory: (email_category_id, options) ->
    options.template = email_category_id
    @registrar.registerNotificationCategory(email_category_id, options)

    return
  
  registerEmails: (category_id, email_defs) ->
    @registrar.registerNotifications(category_id, email_defs)

    return
  
  getHashRequestStringForUnsubscribe: (email_category_id) ->
    return @registrar.getHashRequestStringForUnsubscribe(email_category_id)