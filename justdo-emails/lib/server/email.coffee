JustdoEmails = {}

htmlToText = Npm.require "html-to-text"

getTemplate = (templateName) -> Handlebars.templates[templateName]

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
    # }

    check(options, build_and_send_options_schema)

    # The check above ensures template exists
    template_name = options.template
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
