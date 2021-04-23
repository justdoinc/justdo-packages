if (custom_new_user_delay_ms = amplify.store("email_verification_prompt::custom_new_user_delay_ms"))?
  # To allow easy testing of this feature, a custom delay period can be set in the
  # browser local storage. While on the JustDo webapp, call:
  
  # amplify.store("email_verification_prompt::custom_new_user_delay_ms", time_ms)

  # time_ms is a Number, representing the desired delay in miliseconds for testing
  # purposes.

  # Pass null to clear this custom setting.

  # You MUST refresh the page for the change to take effect.

  # E.g

  # amplify.store("email_verification_prompt::custom_new_user_delay_ms", 1000 * 60 * 5)

  # Once browser refreshed, will require at least 5 mins since user registration
  # to show the dialog, and will show the prompt after 5 mins passed, since user
  # registration (only is user is still unverified).
  new_user_verification_required_delay_period = parseInt(custom_new_user_delay_ms, 10)

  console.warn "justdoinc:justdo-email-verification-prompt : Custom new user delay time is set #{new_user_verification_required_delay_period}. Use: amplify.store('email_verification_prompt::custom_new_user_delay_ms', null) to clear."
else
  new_user_verification_required_delay_period = 1000 * 60 * 60 * 3

_.extend JustdoEmailVerificationPrompt.prototype,
  _immediateInit: ->
    return

  _deferredInit: ->
    @_all_emails_verified_tracker = null

    @new_user_verification_required_delay_timeout = null
    @new_user_verification_required_delay_dep = new Tracker.Dependency()

    @setupAllEmailsVerifiedTracker()

    if @destroyed
      return

    return

  _setNewUserVerificationRequiredDelayInvalidator: (time_to_issue_notice) ->
    if @new_user_verification_required_delay_timeout?
      clearTimeout @new_user_verification_required_delay_timeout

    @new_user_verification_required_delay_dep.depend()

    @new_user_verification_required_delay_timeout = setTimeout =>
      # Note, since 
      @new_user_verification_required_delay_dep.changed()

      return
    , time_to_issue_notice

    return

  setupAllEmailsVerifiedTracker: ->
    pre_init = true
    previous_all_emails_verified_val = undefined

    @_all_emails_verified_tracker = Tracker.autorun =>
      if not (user = Meteor.user({fields: {createdAt: 1, all_emails_verified: 1}}))
        pre_init = true
        previous_all_emails_verified_val = undefined

        return

      if (created_at = user.createdAt)?
        # If user's create at is within the grace period, invalidate this
        # computation when the grace period expires

        time_to_issue_notice =
          new_user_verification_required_delay_period -
            ((new Date()) - created_at)

        if time_to_issue_notice > 0
          @logger.debug "New account, delay email verification dialog presentation by #{time_to_issue_notice} miliseconds (new_user_verification_required_delay_period: #{new_user_verification_required_delay_period})"

          @_setNewUserVerificationRequiredDelayInvalidator(time_to_issue_notice)

          # Don't continue to dialog presentation
          return

      new_all_emails_verified_val = user.all_emails_verified

      if not new_all_emails_verified_val?
        # If all_emails_verified isn't defined
        # hide all dialogs, init flags
        pre_init = true
        previous_all_emails_verified_val = undefined

        @hideEmailVerificationRequiredDialog()
        @hideVerificationCompletedSuccessfullyDialog()
      else if new_all_emails_verified_val == previous_all_emails_verified_val
        # No change, do nothing
      else if previous_all_emails_verified_val is false and new_all_emails_verified_val is true
        # Note, we don't do it when the previous_all_emails_verified_val is undefined,
        # to avoid the @showVerificationCompletedSuccessfullyDialog() from being called
        # on every load...
        @hideEmailVerificationRequiredDialog()
        @showVerificationCompletedSuccessfullyDialog()
      else if new_all_emails_verified_val is true
        @hideEmailVerificationRequiredDialog()
      else if new_all_emails_verified_val is false
        @hideVerificationCompletedSuccessfullyDialog()

        # When in development mode, we don't show the dialog automatically (so the user won't
        # have to setup smtp to play with the JD SDK)
        if APP.development_mode_enabled_rv.get() != true
          @showEmailVerificationRequiredDialog()

      previous_all_emails_verified_val = new_all_emails_verified_val

      return

    @onDestroy ->
      @_all_emails_verified_tracker.stop()
      @_all_emails_verified_tracker = null

      return

    return

  showEmailVerificationRequiredDialog: ->
    if Meteor.user({fields: {all_emails_verified: 1}})?.all_emails_verified isnt false
      console.error "All the user's emails are verified, no need to show the verification required dialog"

      return

    data =
      current_email: -> Meteor.user({fields: {emails: 1}})?.emails[0].address

    message_template =
      JustdoHelpers.renderTemplateInNewNode(Template.email_verification_required_dialog, data)

    @_email_verification_required_dialog = bootbox.dialog
      title: "Please verify your email address"
      message: message_template.node
      className: "email-verification-required-dialog bootbox-new-design"

      onEscape: ->
        return true

      buttons:
        resend_verification_email:
          label: "Resend verification email"

          callback: ->
            APP.accounts.sendVerificationEmail (err) ->
              if err?
                bootbox.alert
                  message: err.reason
                  className: "bootbox-new-design email-verification-prompt-alerts"
                  closeButton: false

                return

              bootbox.alert
                message: "<h4><b>Email verification sent</b></h4><p>If you can't find the verification email, please check your spam folder.</p>"
                className: "bootbox-new-design email-verification-prompt-alerts"
                closeButton: false

            return false

        submit:
          label: "Skip"

          className: "btn-primary"

          callback: ->
            return true

    return

  hideEmailVerificationRequiredDialog: ->
    @_email_verification_required_dialog?.data("bs.modal")?.hide()
    @_email_verification_required_dialog = undefined

    return

  showVerificationCompletedSuccessfullyDialog: ->
    @_verification_completed_successfully_dialog = bootbox.alert
      message: "<b>Email verification completed successfully!</b>"
      className: "bootbox-new-design email-verification-prompt-alerts"
      closeButton: false
      callback: =>
        @_verification_completed_successfully_dialog = undefined

        return true

    return

  hideVerificationCompletedSuccessfullyDialog: ->
    @_verification_completed_successfully_dialog?.data("bs.modal").hide()
    @_verification_completed_successfully_dialog = undefined

    return

