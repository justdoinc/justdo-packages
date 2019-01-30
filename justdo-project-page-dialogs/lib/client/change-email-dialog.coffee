email_regex = JustdoHelpers.common_regexps.email

email_rv = new ReactiveVar()
email_is_valid_rv = new ReactiveVar()
submit_attempted_rv = new ReactiveVar()
initReactiveVars = ->
  email_rv.set ""
  email_is_valid_rv.set false

  submit_attempted_rv.set false

ProjectPageDialogs.editEmail = (cb) ->
  APP.accounts.isPasswordFlowPermittedForCurrentUser (err, allowed) =>
    if err?
      console.error "Failed to fetch isPasswordFlowPermittedForUser"

      return

    if allowed
      _editEmail()
    else
      bootbox.alert
        message: "You must set password in order to change your email"
        className: "bootbox-new-design bootbox-new-design-simple-dialogs-default"
        closeButton: false

      return false

    return

  return

_editEmail = ->
  initReactiveVars(data)

  data =
    current_email: -> Meteor.user()?.emails[0].address

  message_template =
    JustdoHelpers.renderTemplateInNewNode(Template.change_email_dialog, data)

  dialog = bootbox.dialog
    title: "Change Email"
    message: message_template.node
    className: "edit-email-dialog bootbox-new-design"

    onEscape: ->
      return true

    buttons:
      cancel:
        label: "Cancel"

        className: "btn-default"

        callback: ->
          return true

      submit:
        label: "Change Email"

        className: "btn-primary"

        callback: ->
          submit_attempted_rv.set(true)

          Tracker.flush() # So input validation checks in Template autorun will run following submit_attempted_rv change

          if email_is_valid_rv.get()
            if _.isEmpty(password = $("#new-email-password-confirmation").val())
              bootbox.alert
                message: "Enter your password to change your email"
                className: "bootbox-new-design bootbox-new-design-simple-dialogs-default"
                closeButton: false

              return false

            bootbox.confirm
              message: "Are you sure you want to change your account email to: <b>#{email_rv.get()}</b>"
              className: "bootbox-new-design bootbox-new-design-simple-dialogs-default"
              closeButton: false

              callback: (res) ->
                if not res
                  return true

                APP.accounts.changeAccountEmail email_rv.get(), Accounts._hashPassword(password), (err) ->
                  if err?
                    bootbox.alert
                      message: err.reason
                      className: "bootbox-new-design bootbox-new-design-simple-dialogs-default"
                      closeButton: false

                    return

                  dialog.data("bs.modal").hide()

                  return

                return true

          return false

Template.change_email_dialog.helpers
  isInvalidEmail: -> not email_is_valid_rv.get()

Template.change_email_dialog.events
  "keyup #new-email, change #new-email": (e) ->
    email_rv.set($(e.currentTarget).val().trim())

    return

  "keydown #new-email,#new-email-password-confirmation": (e) ->
    if e.which == 13
      $(".edit-email-dialog .modal-footer .btn-primary").click()

    return

  "click .forgot-password-btn": ->
    APP.accounts.sendPasswordResetEmail JustdoHelpers.currentUserMainEmail(), (err) ->
      if err?
        bootbox.alert
          message: err.reason
          className: "bootbox-new-design bootbox-new-design-simple-dialogs-default"
          closeButton: false

        return

      bootbox.alert
        message: "<h4><b>An email sent with password reset instructions</b></h4><p>If you can't find the email, please check your spam folder.</p>"
        className: "bootbox-new-design bootbox-new-design-simple-dialogs-default"
        closeButton: false

    return false

Template.change_email_dialog.onCreated ->
  @autorun ->
    submit_attempted = submit_attempted_rv.get()

    if submit_attempted and (_.isEmpty(email_rv.get()) or not email_regex.test(email_rv.get()))
      email_is_valid_rv.set(false)
    else
      email_is_valid_rv.set(true)

    return

  return