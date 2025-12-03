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
  
  registerEmailCategory: (email_category_id, options) ->
    options.template = email_category_id
    @registrar.registerNotificationCategory(email_category_id, options)

    return
  
  getHashRequestStringForUnsubscribe: (email_category_id) ->
    return @registrar.getHashRequestStringForUnsubscribe(email_category_id)