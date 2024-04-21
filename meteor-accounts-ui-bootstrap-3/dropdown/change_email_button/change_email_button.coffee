Template.login_buttons_open_edit_email_btn.events
  "click #login-buttons-open-edit-email": (e) ->
    ProjectPageDialogs.editEmail()

    return

Template.login_buttons_open_edit_email_btn.helpers
  isAllowAccountsToChangeEmailEnabled: ->
    return env.ALLOW_ACCOUNTS_TO_CHANGE_EMAIL is "true"
