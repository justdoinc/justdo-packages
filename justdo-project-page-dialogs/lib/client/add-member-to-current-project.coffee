#
# General Helpers
#

email_regex = JustdoHelpers.common_regexps.email

#
# ProjectPageDialogs.addMemberToCurrentProject
#

getCurrentProject = -> APP.modules.project_page.helpers.curProj()

showAddNewMemberToTaskReminder = ->
  JustdoSnackbar.show
    text: "Member added successfully.<br />Add the member to tasks you want to share."
    actionText: "Learn More"
    duration: 10000
    onActionClick: ->
      window.open("https://support.justdo.today/hc/en-us/articles/115003577233")

      return

ProjectPageDialogs.addMemberToCurrentProject = (email, invited_members_dialog_options, cb) ->
  # This Dialog assumes that the project route is open, it operates on
  # the loaded project.

  # Notes:
  #
  # * The dialog won't show at all if a user with the given email already exists for the
  #   current project.
  # * cb will get two parameters: (err, member_doc)
  #
  #   err is an error object with a message string under the 'reason' property,
  #   if the operation failed for any reason.
  #   If it is null/undefined it means that user was added successfully.
  #
  #   member_doc is the user document of the added user, will be provided, if
  #   operation didn't failed.

  if not email_regex.test(email)
    JustdoHelpers.callCb cb, {reason: "Invalid email provided"}

    return

  APP.accounts.userExists email, (err, exists) ->
    if err?
      JustdoHelpers.callCb cb, err

      return

    if exists
      getCurrentProject().inviteMember {email: email}, (err, user_id) ->
        if err?
          JustdoHelpers.callCb cb, err

          return

        JustdoHelpers.callCb cb, null, user_id

        showAddNewMemberToTaskReminder()

        return

      return

    # ELSE
    # User doesn't exist in Justdo yet. Show the dialog that asks for some more
    # details to prepare an invite to Justdo.

    invited_members_dialog_options = _.extend {}, invited_members_dialog_options,
      title: "Add a New Member"
      buttons: 
        cancel:
          label: "Cancel"

          className: "btn-default"

          callback: ->
            return true

        submit:
          label: "Add Member"

          callback: =>
            submit_attempted_rv.set(true)

            Tracker.flush() # So input validation checks in Template autorun will run following submit_attempted_rv change

            if email_is_valid_rv.get() and first_name_is_valid_rv.get() and last_name_is_valid_rv.get()
              profile =
                first_name: first_name_rv.get()
                last_name: last_name_rv.get()

              email = email_rv.get()

              getCurrentProject().inviteMember {email: email, profile: profile}, (err, user_id) ->
                if err
                  if err.error == "member-already-exists"
                    error_message = "Member <i>#{JustdoHelpers.xssGuard(JustdoHelpers.displayName(Meteor.users.findOne({"emails.address": email})))}</i> (#{email}) already exist in this project."
                  else
                    error_message = err.reason
                  bootbox.alert
                    message: error_message
                    className: "bootbox-new-design members-management-alerts"
                    closeButton: false

                  return

                JustdoHelpers.callCb cb, null, user_id

                showAddNewMemberToTaskReminder()

                dialog.data("bs.modal").hide()

            return false

    dialog = initInvitedMembersDialog {email}, invited_members_dialog_options

  return

#
# ProjectPageDialogs.editEnrolledMember
#

ProjectPageDialogs.editEnrolledMember = (user_id, invited_members_dialog_options) ->
  # At the moment, we assume this method is called from a project page on which 
  # user_id is Awaiting Registration.
  #
  # Notes:
  #
  # * The dialog won't show at all if user_id isn't Awaiting Registration, or if logged
  #   in member, isn't allowed to edit user_id's details.

  if not (user = Meteor.users.findOne(user_id))?
    APP.logger.debug("[ProjectPageDialogs.editEnrolledMember] user_id #{user_id} isn't known by the active publications. Note, this method must be called from a project page on which user_id appears under the Awaiting Registration list.")

    return

  if not user.invited_by == Meteor.userId()
    APP.logger.debug("[ProjectPageDialogs.editEnrolledMember] Only the inviting user can edit invited member's details.")

    return

  processEditRequest = (options) ->
    options = _.extend {force_enrollment_email_resend: false}, options

    if email_is_valid_rv.get() and first_name_is_valid_rv.get() and last_name_is_valid_rv.get()
      APP.accounts.editPreEnrollmentUserData user_id, {email: email_rv.get(), first_name: first_name_rv.get(), last_name: last_name_rv.get()}, (err, result) ->
        if err?
          bootbox.alert
            message: err.reason
            className: "bootbox-new-design members-management-alerts"
            closeButton: false

          return

        if options.force_enrollment_email_resend or result.email_changed
          APP.projects.resendEnrollmentEmail getCurrentProject()?.id, user_id, (err) ->
            if err?
              bootbox.alert
                message: err.reason
                className: "bootbox-new-design members-management-alerts"
                closeButton: false

              return

            dialog.data("bs.modal").hide()

            return
        else
          dialog.data("bs.modal").hide()

        return
    
    return

  invited_members_dialog_options = _.extend {}, invited_members_dialog_options,
    title: "Edit invited member's details"
    buttons: 
      cancel:
        label: "Cancel"

        className: "btn-default"

        callback: ->
          return true

      resubmit:
        label: "Resend Invitation Email"

        callback: =>
          submit_attempted_rv.set(true)

          Tracker.flush() # So input validation checks in Template autorun will run following submit_attempted_rv change

          processEditRequest({force_enrollment_email_resend: true})

          return false

      submit:
        label: "Update"

        className: "btn-primary"

        callback: =>
          submit_attempted_rv.set(true)

          Tracker.flush() # So input validation checks in Template autorun will run following submit_attempted_rv change

          processEditRequest({force_enrollment_email_resend: false})

          return false

  dialog = initInvitedMembersDialog {email: user.emails?[0]?.address, first_name: user.profile?.first_name,  last_name: user.profile?.last_name}, invited_members_dialog_options

  return

#
# Invited Members Dialog
#

first_name_rv = new ReactiveVar()
first_name_is_valid_rv = new ReactiveVar()
email_rv = new ReactiveVar()
email_is_valid_rv = new ReactiveVar()
last_name_rv = new ReactiveVar()
last_name_is_valid_rv = new ReactiveVar()
submit_attempted_rv = new ReactiveVar()
initReactiveVars = (init_vals) ->
  {email, first_name, last_name} = init_vals

  first_name_rv.set first_name or ""
  first_name_is_valid_rv.set false
  email_rv.set email or ""
  email_is_valid_rv.set false
  last_name_rv.set last_name or ""
  last_name_is_valid_rv.set false

  submit_attempted_rv.set false

initInvitedMembersDialog = (data, options) ->
  default_options =
    title: "SET TITLE"
    custom_classes: ""
    buttons:
      cancel:
        label: "Cancel"

        className: "btn-default"

        callback: ->
          return true

  options = _.extend default_options, options

  initReactiveVars(data)

  message_template =
    APP.helpers.renderTemplateInNewNode(Template.invite_new_user_dialog, data)

  dialog = bootbox.dialog
    title: options.title
    message: message_template.node
    animate: false
    className: "invite-new-user-dialog bootbox-new-design #{options.custom_classes}"

    onEscape: ->
      return true

    buttons: options.buttons

  $("#new-user-first-name").focus()

  return dialog

Template.invite_new_user_dialog.onCreated ->
  @autorun ->
    submit_attempted = submit_attempted_rv.get()

    if submit_attempted and (_.isEmpty(email_rv.get()) or not email_regex.test(email_rv.get()))
      email_is_valid_rv.set(false)
    else
      email_is_valid_rv.set(true)

    if submit_attempted and _.isEmpty(first_name_rv.get())
      first_name_is_valid_rv.set(false)
    else
      first_name_is_valid_rv.set(true)

    if submit_attempted and _.isEmpty(last_name_rv.get())
      last_name_is_valid_rv.set(false)
    else
      last_name_is_valid_rv.set(true)

Template.invite_new_user_dialog.helpers
  isInvalidEmail: -> not email_is_valid_rv.get()
  isInvalidFirstName: -> not first_name_is_valid_rv.get()
  isInvalidLastName: -> not last_name_is_valid_rv.get()

Template.invite_new_user_dialog.events
  "keyup #new-user-email, change #new-user-email": (e) ->
    email_rv.set($(e.currentTarget).val().trim())

    return

  "keyup #new-user-first-name, change #new-user-first-name": (e) ->
    first_name_rv.set($(e.currentTarget).val().trim())

    return

  "keyup #new-user-last-name, change #new-user-last-name": (e) ->
    last_name_rv.set($(e.currentTarget).val().trim())

    return

  "keydown #new-user-first-name,#new-user-last-name,#new-user-email": (e) ->
    if e.which == 13
      $(".modal-footer .btn-primary").click()

    return
