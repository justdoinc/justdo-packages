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
  
  registerEmailType: (email_type_id, options) ->
    options.template = email_type_id
    @registrar.registerNotificationType(email_type_id, options)

    return
  
  unsubscribeFromType: (user_id, email_type_id) ->
    @registrar.unsubscribeUserFromNotificationType(user_id, email_type_id)

    return