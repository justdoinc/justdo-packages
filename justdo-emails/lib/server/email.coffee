htmlToText = Npm.require "html-to-text"

getTemplate = (templateName) -> Handlebars.templates[templateName]

forbidden_email_domains = ["example.com"]

build_and_send_options_schema = new SimpleSchema
  to:
    label: "To"
    type: String
    regEx: JustdoHelpers.common_regexps.email
  template:
    label: "Template"
    type: String
    custom: ->
      if not getTemplate(@value)?
        return "Unknown email template #{@value}"

      return undefined
  template_data:
    label: "Template data"
    type: Object
    blackbox: true
    optional: true
  subject:
    label: "Subject"
    type: String
    optional: true
  bypass_notification_registrar:
    label: "Bypass notification registrar"
    type: Boolean
    optional: true

_.extend JustdoEmails,
  options:
    default_sender: "your.assistant@justdo.com"
    site_name: "JustDo"
    logo_path: Meteor.absoluteUrl "layout/logos/justdo_logo_for_emails.png"
    default_subjects:
      "email-verification": "Verify your email address" # if you change this, update also: packages/justdo-email-verification-prompt/lib/client/email-verification-required-dialog/email-verification-required-dialog.html
      "password-recovery": "Password Recovery"
      "notifications-iv-unread-chat.handlebars": "New chat message"
      "notifications-added-to-new-project": "You were added to a JustDo"
      "ownership-transfer-rejected": "Task ownership transfer rejected"
      "ownership-transfer": "Task ownership transfer request"
      "contact-request": "New Contact Request"

    wrapper_template: "email-wrapper"

  _buildEmail: (html_content, notification_def) ->
    #
    # Build wrapper
    #
    email_wrapper_data =
      body: html_content
      logo_path: @options.logo_path
      landing_app_root_url: process.env?.LANDING_APP_ROOT_URL
      hide_footer: notification_def.custom_options?.hide_footer
      hide_unsubscribe_links: notification_def.custom_options?.hide_unsubscribe_links

    template_name = notification_def._id
    notification_category_id = notification_def.notification_category
    if (notification_category_def = @registrar.getNotificationCategory(notification_category_id))?
      # Note that we use `getNotificationCategory` instead of `requireNotificationCategory` here,
      # to support the case where `bypass_notification_registrar` is true, and the notification is not registered.
      email_wrapper_data = _.extend email_wrapper_data,
        email_type_label: JustdoHelpers.lcFirst TAPi18n.__ notification_category_def.label_i18n # Currently translated to default lang only
        unsubscribe_link: Meteor.absoluteUrl "##{@getHashRequestStringForUnsubscribe(notification_category_id)}"
        unsubscribe_all_link: Meteor.absoluteUrl "##{@getHashRequestStringForUnsubscribe("all")}"
        
    email_html = getTemplate(@options.wrapper_template) email_wrapper_data

    inlined_html = juice email_html

    doctype = '<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">'

    return doctype + inlined_html

  _send: (to, subject, html, text) ->
    from = JustdoEmails.options.default_sender

    if typeof text == "undefined"
      text = htmlToText.fromString(html, wordwrap: 130)

    email =
      from: from
      to: to
      subject: subject
      text: text
      html: html

    APP.justdo_analytics.logServerRecordEncryptVal
      cat: "comm"
      act: "email-out"
      val: EJSON.stringify({to, subject})

    Email.send email

    return email

  buildAndSend: (options) ->
    # Options structure:
    #
    # {
    #   to: (string, required) address to send email to
    #   template: (string, required) email template
    #   template_data: (object, optional) email template_data
    #   subject: (string, optional) email subject, if not provided, the default
    #            template subject will be used from @options.default_subjects
    #            @options.site_name will always add as subject suffix
    #   bypass_notification_registrar: (boolean, optional): If true, we treat Justdo Emails as a simple email delivery service 
    #                                                       by bypassing completely every checks from the notification registrar, 
    #                                                       and sending the email directly to the recepient.
    #                                                       This means that:
    #                                                       1. We don't require the email address to be associated with a user
    #                                                       2. We don't require the email template to be registered in the notification registrar
    #                                                       3. We don't check whether the receiving user has unsubscribed from any notification
    # }

    check(options, build_and_send_options_schema)

    if options.to.split("@")[1] in forbidden_email_domains
      console.warn "An email to a forbidden email domain skipped (#{options.to})"
      return
  
    template_name = options.template

    if not options.bypass_notification_registrar
      # Validate that the notification is registered (throws if not found)
      notification_def = @registrar.requireNotification(template_name)
      
      receiving_user_query_options =
        fields: _.extend @registrar._getUserPreferredSubdocumentFields(),
          is_proxy: 1
      receiving_user_doc = JustdoHelpers.getUserByEmail(options.to, receiving_user_query_options)

      if not receiving_user_doc?
        console.warn "A user with email address #{options.to} not found"
        return

      if not notification_def.custom_options?.send_to_proxy_users and APP.accounts.isProxyUser(receiving_user_doc)
        console.warn "An email to a proxy account skipped (#{options.to})"
        return

      # Skip if user has unsubscribed from the notification
      # This also handles the case where the user has unsubscribed from all notifications.
      if @registrar.isUserUnsubscribedFromNotification receiving_user_doc, template_name
        console.warn "An email to a user who has unsubscribed from the notification #{template_name} skipped (#{options.to})"
        return
    else
      # If the bypass_notification_registrar is true, we don't check if the notification is registered,
      # and create a dummy notification definition to be passed to the _buildEmail method.
      notification_def = 
        _id: template_name

    # Ensure the handlebars template exists
    template = getTemplate(template_name)

    template_data = {}
    if _.isObject(options.template_data)
      template_data = options.template_data

    if options.subject? and not _.isEmpty(options.subject)
      subject = options.subject
    else if (default_subject = @options.default_subjects[template_name])?
      subject = default_subject
    else
      subject = "Update"

    subject += " - #{@options.site_name}"

    template_html = template(template_data)

    email_html = JustdoEmails._buildEmail template_html, notification_def

    return JustdoEmails._send options.to, subject, email_html

APP.getEnv (env) ->
  if (default_sender = env.MAIL_SENDER_EMAIL)?
    JustdoEmails.options.default_sender = default_sender

  return
