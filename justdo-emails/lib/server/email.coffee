htmlToText = Npm.require "html-to-text"

getTemplate = (templateName) -> Handlebars.templates[templateName]

forbidden_email_domains = ["example.com"]

# Proxy users, and users unsubscribed from all emails, will still receive emails from these templates
templates_ignoring_user_preference = ["email-verification", "password-recovery"]

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

  _buildEmail: (html_content) ->
    #
    # Build wrapper
    #
    email_wrapper_data =
      body: html_content
      logo_path: @options.logo_path
      landing_app_root_url: process.env?.LANDING_APP_ROOT_URL

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
    #   bypass_notification_registrar: (boolean, optional) if true, the email will be sent directly to the recepient, 
    #                                                      without checking whether the user has unsubscribed from the notification.
    # }

    check(options, build_and_send_options_schema)

    if options.to.split("@")[1] in forbidden_email_domains
      console.warn "An email to a forbidden email domain skipped (#{options.to})"
      return
  
    template_name = options.template
    
    if not options.bypass_notification_registrar
      receiving_user_query =
        "emails.address": options.to
      receiving_user_query_options =
        fields:
          is_proxy: 1
          "profile.#{JustdoEmails.user_preference_subdocument_id}": 1
      receiving_user_doc = Meteor.users.findOne(receiving_user_query, receiving_user_query_options)
      if not receiving_user_doc?
        console.warn "A user with email address #{options.to} not found"
        return
      
      if not @registrar.isNotificationIgnoringUserUnsubscribePreference(options.template)
        # If the notification respects user unsubscribe preference, check the following.

        # Forbid proxy users from receiving any emails
        if APP.accounts.isProxyUser receiving_user_doc
          console.warn "An email to a proxy account skipped (#{options.to})"
          return

        # Skip if user has unsubscribed from the notification
        # This also handles the case where the user has unsubscribed from all notifications.
        if @registrar.isUserUnsubscribedFromNotification receiving_user_doc, template_name
          console.warn "An email to a user who has unsubscribed from the notification #{options.template} skipped (#{options.to})"
          return

    # The check above ensures template exists
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

    email_html = JustdoEmails._buildEmail template_html

    return JustdoEmails._send options.to, subject, email_html

APP.getEnv (env) ->
  if (default_sender = env.MAIL_SENDER_EMAIL)?
    JustdoEmails.options.default_sender = default_sender

  return
