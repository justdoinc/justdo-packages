loginButtonsSession = Accounts._loginButtonsSession

Template.login_buttons_open_change_password_btn.onCreated ->
  @user_has_password = new ReactiveVar false

  APP.accounts.isPasswordFlowPermittedForCurrentUser (err, allowed) =>
    if err?
      console.error "Failed to fetch isPasswordFlowPermittedForUser"

      return

    @user_has_password.set allowed

    return

Template.login_buttons_open_change_password_btn.helpers
  isAccountsPasswordEnabled: ->
    return env.ALLOW_ACCOUNTS_PASSWORD_BASED_LOGIN is "true"

  userHasPassword: ->
    return Template.instance().user_has_password.get()

Template.login_buttons_open_change_password_btn.events
  "click #login-buttons-open-change-password": (e) ->
    e.stopPropagation()
    loginButtonsSession.resetMessages()

    loginButtonsSession.set('inChangePasswordFlow', true)
    Tracker.flush()

  "click #login-buttons-open-set-password": (e) ->
    APP.accounts.sendPasswordResetEmail JustdoHelpers.currentUserMainEmail(), (err) ->
      if err?
        bootbox.alert
          message: err.reason
          className: "bootbox-new-design change-email-dialog-alerts"
          closeButton: false

        return

      bootbox.alert
        message: "<h4><b>An email sent to #{JustdoHelpers.currentUserMainEmail()} with password settings instructions</b></h4><p>If you can't find the email, please check your spam folder.</p>"
        className: "bootbox-new-design change-email-dialog-alerts"
        closeButton: false

    return false
