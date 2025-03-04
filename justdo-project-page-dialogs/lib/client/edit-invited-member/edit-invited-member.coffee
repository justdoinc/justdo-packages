#
# General Helpers
#

email_regex = JustdoHelpers.common_regexps.email
inviteeTerm = (guest_term) -> if guest_term then "guest" else "member"
getCurrentProject = -> APP.modules.project_page.helpers.curProj()

#
# ProjectPageDialogs.editProxyUser
#

ProjectPageDialogs.editProxyUser = (proxy_user_id, callback) ->
  # This method allows site admins to edit proxy user details
  # Only site admins can edit proxy users
  
  # Verify user is a site admin
  unless APP.justdo_site_admins.isCurrentUserSiteAdmin()
    return
    
  # Verify the target is a proxy user
  proxy_user = Meteor.users.findOne {_id: proxy_user_id, is_proxy: true}, 
                {fields: {profile: 1, emails: 1, is_proxy: 1}}
  
  unless proxy_user?.is_proxy
    APP.logger.debug("[ProjectPageDialogs.editProxyUser] user_id #{proxy_user_id} is not a proxy user")
    return
    
  processProxyUserEdit = (cb) ->
    if email_is_valid_rv.get() and first_name_is_valid_rv.get() and last_name_is_valid_rv.get()
      # Get values from reactive vars
      update_properties = 
        profile:
          first_name: first_name_rv.get()
          last_name: last_name_rv.get()
      
      # Add email if it changed
      if email_rv.get() != proxy_user.emails?[0]?.address
        update_properties.email = email_rv.get()
      
      # Call the server method
      Meteor.call "saUpdateProxyUser", proxy_user_id, update_properties, (err, result) ->
        if err?
          bootbox.alert
            message: err.reason or "Failed to update proxy user"
            className: "bootbox-new-design members-management-alerts"
            closeButton: false
          cb? err
          return
          
        dialog.data("bs.modal").hide()
        cb? null, result
        return
        
    return
  
  # Set up reactive vars with current values
  initReactiveVars
    email: proxy_user.emails?[0]?.address
    first_name: proxy_user.profile?.first_name
    last_name: proxy_user.profile?.last_name
    
  # Set up buttons
  buttons = 
    cancel:
      label: "Cancel"
      className: "btn-light"
      callback: ->
        return true
        
    submit:
      label: "Update"
      className: "btn-primary"
      callback: =>
        submit_attempted_rv.set(true)
        Tracker.flush() # So input validation checks in Template autorun will run
        processProxyUserEdit(callback)
        return false
        
  # Create dialog options
  dialog_options =
    title: "Edit Proxy User"
    view_only: false
    edit_state: true
    is_proxy_user: true   # Flag to indicate this is for a proxy user
    custom_classes: "edit-proxy-user-dialog"
    buttons: buttons
    
  # Show dialog
  dialog = initInvitedMembersDialog
    email: proxy_user.emails?[0]?.address
    first_name: proxy_user.profile?.first_name
    last_name: proxy_user.profile?.last_name
  , dialog_options
  
  return

#
# ProjectPageDialogs.editEnrolledMember
#

ProjectPageDialogs.editEnrolledMember = (user_id, invited_members_dialog_options, callback) ->
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

  invited_members_dialog_options = _.extend {add_as_guest: false}, invited_members_dialog_options

  resendEnrollmentEmail = (cb) ->
    APP.projects.resendEnrollmentEmail getCurrentProject()?.id, user_id, (err) ->
      if err?
        bootbox.alert
          message: err.reason
          className: "bootbox-new-design members-management-alerts"
          closeButton: false

        return

      JustdoHelpers.callCb cb

      return

    return

  processEditRequest = (options, cb) ->
    options = _.extend {force_enrollment_email_resend: false}, options

    if email_is_valid_rv.get() and first_name_is_valid_rv.get() and last_name_is_valid_rv.get()
      APP.accounts.editPreEnrollmentUserData user_id, {email: email_rv.get(), first_name: first_name_rv.get(), last_name: last_name_rv.get()}, (err, result) ->
        if err?
          bootbox.alert
            message: err.reason
            className: "bootbox-new-design members-management-alerts"
            closeButton: false
          cb? err

          return

        if options.force_enrollment_email_resend or result.email_changed
          resendEnrollmentEmail (err) ->
            dialog.data("bs.modal").hide()

            return
        else
          dialog.data("bs.modal").hide()

        cb? null, result

        return

    return

  user_allowed_to_edit = false
  if (user_doc = Meteor.users.findOne(user_id, {fields: {invited_by: 1, users_allowed_to_edit_pre_enrollment: 1}}))?
    users_allowed_to_edit_pre_enrollment = (user_doc.users_allowed_to_edit_pre_enrollment or []).slice() # slice to avoid edit by reference
    if _.isString(user_doc.invited_by)
      users_allowed_to_edit_pre_enrollment.push user_doc.invited_by

    user_allowed_to_edit = Meteor.userId() in users_allowed_to_edit_pre_enrollment

  buttons = 
    cancel:
      label: "Cancel"

      className: "btn-light"

      callback: ->
        return true

    resubmit:
      label: "Resend Invitation Email"

      className: "btn-light"

      callback: =>
        submit_attempted_rv.set(true)

        Tracker.flush() # So input validation checks in Template autorun will run following submit_attempted_rv change

        if user_allowed_to_edit
          processEditRequest({force_enrollment_email_resend: true}, callback)
        else
          resendEnrollmentEmail ->
            dialog.data("bs.modal").hide()

            return
        return false

  if user_allowed_to_edit
    buttons.submit =
      label: "Update"

      className: "btn-primary"

      callback: =>
        submit_attempted_rv.set(true)

        Tracker.flush() # So input validation checks in Template autorun will run following submit_attempted_rv change

        processEditRequest({force_enrollment_email_resend: false}, callback)

        return false

  invited_members_dialog_options = _.extend {}, invited_members_dialog_options,
    title: "Edit invited #{inviteeTerm(invited_members_dialog_options.add_as_guest)}'s details"
    view_only: not user_allowed_to_edit
    edit_state: true
    buttons: buttons

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
    add_as_guest: false
    custom_classes: ""
    view_only: false
    buttons:
      cancel:
        label: "Cancel"

        className: "btn-light"

        callback: ->
          return true

  options = _.extend default_options, options

  initReactiveVars(data)

  _.extend data, {add_as_guest: options.add_as_guest, view_only: options.view_only, edit_state: options.edit_state}

  message_template =
    APP.helpers.renderTemplateInNewNode(Template.edit_invited_member_dialog, data)

  dialog = bootbox.dialog
    title: options.title
    message: message_template.node
    animate: false
    className: "edit-invited-member-dialog bootbox-new-design #{options.custom_classes}"

    onEscape: ->
      return true

    buttons: options.buttons

  $("#new-user-first-name").focus()

  return dialog

Template.edit_invited_member_dialog.onCreated ->
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

Template.edit_invited_member_dialog.helpers
  isInvalidEmail: -> not email_is_valid_rv.get()
  isInvalidFirstName: -> not first_name_is_valid_rv.get()
  isInvalidLastName: -> not last_name_is_valid_rv.get()
  inviteeTerm: -> inviteeTerm(@add_as_guest)
  isSdkBuild: -> APP.justdo_site_admins.getLicense()?.license?.is_sdk is true
  is_proxy_user: -> @is_proxy_user

Template.edit_invited_member_dialog.events
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
