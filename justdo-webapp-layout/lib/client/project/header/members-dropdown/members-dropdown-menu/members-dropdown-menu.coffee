APP.executeAfterAppLibCode ->
  module = APP.modules.project_page
  curProj = module.helpers.curProj

  addMembersDropDownError = (error_message) ->
    # Currently, we show up to one error at a time
    clearMembersDropDownErrors()

    error_elem = """
      <div class="alert alert-danger mt-3 mb-0 px-3 py-2" role="alert">
        <button type="button" class="close" data-dismiss="alert" aria-label="Close"><span aria-hidden="true">&times;</span></button>
        <span class="glyphicon glyphicon-exclamation-sign" aria-hidden="true"></span>
        <span class="sr-only">Error:</span>
        #{error_message}
      </div>
    """

    $(error_elem)
      .prependTo(".members-dropdown-menu .alerts-container")
      .on "click", ".close", (e) ->
        e.stopPropagation()
        $(e.currentTarget).closest(".alert").remove()

  clearMembersDropDownErrors = ->
    $(".members-dropdown-menu .alert").remove()

  addFilledUser = ->
    clearMembersDropDownErrors()

    email_input = $(".add-members-comp input")

    email = email_input.val().trim().toLowerCase()

    postSuccessProcedures = ->
      # Success procedures
      clearMembersDropDownErrors()
      email_input.val("") # clear input

    ProjectPageDialogs.addMemberToCurrentProject email, {}, (err, user_id) ->
      if $(".members-search-input").val().length > 0
        $(".members-search-input").val("").keyup()

      Tracker.flush()

      JustdoHelpers.newComputedReactiveVar null, (crv) ->
        if $(".members-dropdown-menu:visible").length == 0
          # Stop crv when the dropdown menu is closed
          crv.stop()

          return

        user_item = $(".member-item[user-id='#{user_id}']")
        if user_item.length > 0
          user_item.get(0).scrollIntoView()

          # Stop crv when the member found
          crv.stop()

        return
      ,
        recomp_interval: 100 # Check every 100ms whether user opened the dropdown

      if err?
        addMembersDropDownError err.reason

        return

      postSuccessProcedures()

      return

  Template.members_dropdown_menu.onCreated ->
    @members_filter = new ReactiveVar null
    return

  Template.members_dropdown_menu.onRendered ->
    $("#project-members-dropdown").on "show.bs.dropdown", ->
      setTimeout (->
        $(".members-search-input").focus()
      ), 500
      return
    return

  Template.members_dropdown_menu.helpers module.template_helpers

  Template.members_dropdown_menu.helpers
    getCurrentMembersFilter: ->
      tpl = Template.instance()

      return tpl.members_filter.get()

    isEmptyResults: (filter) ->
      empty = _.isEmpty(module.template_helpers.project_enrolled_admins_sorted_by_first_name(filter)) and
        _.isEmpty(module.template_helpers.project_enrolled_regular_members_sorted_by_first_name(filter)) and
        _.isEmpty(module.template_helpers.project_non_enrolled_members_sorted_by_first_name(filter))

      return empty

  Template.members_dropdown_menu.events
    "click .add-members-comp button": (e) ->
      addFilledUser()

    "keypress .add-members-comp input": (e) ->
      if e.keyCode == 13
        addFilledUser()

    "click .remove": (e) ->
      if @user_id == Meteor.userId()
        confirm_message = "Are you sure you want to leave this JustDo?"
      else
        confirm_message = "Are you sure you want to remove this member?"

      bootbox.confirm
        message: confirm_message
        className: "bootbox-new-design members-management-alerts"
        closeButton: false
        callback: (res) =>
          if res
            curProj().removeMember @user_id, (err) ->
              clearMembersDropDownErrors()
              if err?
                addMembersDropDownError err.reason

          return

    "click .upgrade-admin": (e) ->
      confirm_message = "Are you sure you want to make this member admin of this JustDo?"

      bootbox.confirm
        message: confirm_message
        className: "bootbox-new-design members-management-alerts"
        closeButton: false
        callback: (res) =>
          if res
            curProj().upgradeAdmin @user_id, (err) ->
              clearMembersDropDownErrors()
              if err?
                addMembersDropDownError err.reason

          return

    "click .downgrade-admin": (e) ->
      if @user_id == Meteor.userId()
        confirm_message = "Are you sure you want to stop manage this JustDo?"
      else
        confirm_message = "Are you sure you want to remove this admin?"

      bootbox.confirm
        message: confirm_message
        className: "bootbox-new-design members-management-alerts"
        closeButton: false
        callback: (res) =>
          if res
            curProj().downgradeAdmin @user_id, (err) ->
              clearMembersDropDownErrors()
              if err?
                addMembersDropDownError err.reason

          return

    "keyup .members-search-input": (e, template) ->
      value = $(e.target).val().trim()

      if _.isEmpty value
        return template.members_filter.set(null)
      else
        template.members_filter.set(value)

      return

    "click .members-dropdown-menu": (e, tpl) ->
      e.stopPropagation() # need to avoit close dropdown on click

      return

  Template.admin_member_item.helpers module.template_helpers
  Template.regular_member_item.helpers module.template_helpers
  Template.enrollment_pending_member.helpers module.template_helpers

  Template.enrollment_pending_member.events
    "click .edit-enrolled": ->
      ProjectPageDialogs.editEnrolledMember @user_id

      return
