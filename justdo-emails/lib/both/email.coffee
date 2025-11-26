JustdoEmails = {}

_.extend JustdoEmails,
  user_preference_subdocument_id: "justdo_emails"

_.extend JustdoEmails,
  registry: JustdoHelpers.createNotificationRegistrar
    user_preference_subdocument_id: JustdoEmails.user_preference_subdocument_id
  
  registerEmailTemplate: (template_id, options) ->
    # `template_id` should be the same as the name of the Handlebars template file.
    # In justdo-emails, the `notification_id` is the same as the `template_id` passed to `registerEmaification`
    options.template = template_id
    @registry.registerNotification(template_id, options)

    return