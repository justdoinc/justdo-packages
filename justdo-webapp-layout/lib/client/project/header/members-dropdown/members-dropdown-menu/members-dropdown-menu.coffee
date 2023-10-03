APP.executeAfterAppLibCode ->
  module = APP.modules.project_page
  curProj = module.helpers.curProj

  share.MembersDropdown = JustdoHelpers.generateNewTemplateDropdown "members-dropdown-menu", "members_dropdown_menu",
    custom_bound_element_options:
      close_button_html: null

    updateDropdownPosition: ($connected_element) ->
      @$dropdown
        .position
          of: $connected_element
          my: "right top"
          at: "right bottom"
          collision: "fit fit"
          using: (new_position, details) =>
            target = details.target
            element = details.element
            element.element.addClass "animate slideIn shadow-lg"
            element.element.css
              top: new_position.top - 11
              left: new_position.left

        $(".dropdown-menu.show").removeClass("show") # Hide dropdown

      return

  addMembersDropDownError = (errors_array) ->
    clearMembersDropDownErrors()

    error_elem = ""

    for error_message in errors_array
      error_elem += """
        <div class="alert alert-danger" role="alert">
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

  removeMember = (user_id) ->
    if user_id == Meteor.userId()
      confirm_message = "Are you sure you want to leave this JustDo?"
    else
      confirm_message = "Are you sure you want to remove this member?"

    bootbox.confirm
      message: confirm_message
      className: "bootbox-new-design members-management-alerts"
      closeButton: false
      callback: (res) =>
        if res
          curProj().removeMember user_id, (err) ->
            clearMembersDropDownErrors()
            if err?
              addMembersDropDownError [err.reason]

        return

    return

  Template.members_dropdown_menu.onCreated ->
    tpl = @
    @members_filter = new ReactiveVar null
    @select_mode = new ReactiveVar false
    @selected_members = new ReactiveVar []
    @invite_mode = new ReactiveVar false
    @invited_members_count = new ReactiveVar 0

    tpl.switch_to_invite_mode = ->
      @invited_members_count.set 0
      input = $(".invite-members-input")
      input.val tpl.members_filter.get()

      setTimeout ->
        input.focus()

        setTimeout -> # Move caret at the end of the text inside the input
          input[0].setSelectionRange(input[0].value.length, input[0].value.length)
        , 0
      , 500

      tpl.invite_mode.set true

      return

    tpl.autorun ->
      invite_mode = tpl.invite_mode.get()
      if not invite_mode
        tpl.members_filter.set ""
        $(".invite-members-input").val ""
        $(".members-search-input").val("").focus()
        $(".project-members-container").scrollTop(0)

      return

    return

  Template.members_dropdown_menu.onRendered ->
    $(".members-search-input").focus()

    return

  Template.members_dropdown_menu.helpers module.template_helpers

  Template.members_dropdown_menu.helpers
    getCurrentMembersFilter: ->
      tpl = Template.instance()

      return tpl.members_filter.get()

    isEmptyResults: (filter) ->
      empty = _.isEmpty(module.template_helpers.project_enrolled_admins_sorted_by_first_name(filter)) and
        _.isEmpty(module.template_helpers.project_enrolled_regular_members_sorted_by_first_name(filter)) and
        _.isEmpty(module.template_helpers.project_enrolled_guests_sorted_by_first_name(filter)) and
        _.isEmpty(module.template_helpers.project_non_enrolled_guests_sorted_by_first_name(filter)) and
        _.isEmpty(module.template_helpers.project_non_enrolled_members_sorted_by_first_name(filter))

      return empty

    selectMode: ->
      return Template.instance().select_mode.get()

    memberSelected: ->
      selected_members = Template.instance().selected_members.get()

      return selected_members.includes @_id

    selectedMembersCount: ->
      return Template.instance().selected_members.get().length

    allowRemoveSelected: ->
      return Template.instance().selected_members.get().length > 0

    inviteMode: ->
      return Template.instance().invite_mode.get()

    inviteModeRV: ->
      return Template.instance().invite_mode

    invitedMembersCountRV: ->
      return Template.instance().invited_members_count

    invitedMembersNotification: ->
      notification = ""
      invited_members_count = Template.instance().invited_members_count.get()

      if invited_members_count > 0
        notification += "#{invited_members_count}"

        if invited_members_count == 1
          notification += """ <span>member</span> was invited"""
        else
          notification += """ <span>members</span> were invited"""
      else
        notification = ""

      return notification

  Template.members_dropdown_menu.events
    # "click .show-add-members-dialog": (e, tpl) ->
    #   ProjectPageDialogs.showMemberDialog()
    #
    #   return

    "click .remove": (e, tpl) ->
      if curProj()?.isAdmin()
        tpl.selected_members.set [@_id]
        tpl.select_mode.set true
        clearMembersDropDownErrors()
      else
        removeMember(@_id)
      return

    "click .leave": (e) ->
      removeMember(@_id)

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
                addMembersDropDownError [err.reason]

          return

    "click .make-guest": (e) ->
      confirm_message = "Are you sure you want to make this member a guest of this JustDo?"

      bootbox.confirm
        message: confirm_message
        className: "bootbox-new-design members-management-alerts"
        closeButton: false
        callback: (res) =>
          if res
            curProj().makeGuest @user_id, (err) ->
              clearMembersDropDownErrors()
              if err?
                addMembersDropDownError [err.reason]

          return

    "click .upgrade-guest": (e) ->
      confirm_message = "Are you sure you want to make this guest a member of this JustDo?<br />Once a member, all the other guests/members/admins of this JustDo will become visible to this guest."

      bootbox.confirm
        message: confirm_message
        className: "bootbox-new-design members-management-alerts"
        closeButton: false
        callback: (res) =>
          if res
            curProj().upgradeGuest @user_id, (err) ->
              clearMembersDropDownErrors()
              if err?
                addMembersDropDownError [err.reason]

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
                addMembersDropDownError [err.reason]

          return

    "click .selected-mode .member-item": (e, tpl) ->
      selected_members = tpl.selected_members.get()
      member_id = @_id

      if selected_members.includes member_id
        selected_members = _.without(selected_members, member_id)
      else
        selected_members.push member_id

      tpl.selected_members.set selected_members

      return

    "click .cancel-select-mode": (e, tpl) ->
      tpl.select_mode.set false
      tpl.selected_members.set []

      return

    "click .remove-selected": (e, tpl) ->
      selected_members = tpl.selected_members.get()
      errors = []
      confirm_message = "Are you sure you want to remove #{selected_members.length} members"
      selected_members_count = selected_members.length

      if selected_members_count == 1
        if selected_members[0] == Meteor.userId()
          confirm_message = "Are you sure you want to leave this JustDo?"
        else
          confirm_message = "Are you sure you want to remove this member?"

      bootbox.confirm
        message: confirm_message
        className: "bootbox-new-design members-management-alerts"
        closeButton: false
        callback: (res) =>
          if res
            clearMembersDropDownErrors()

            for member_id in selected_members
              curProj().removeMember member_id, (err) ->
                if err?
                  errors.push err.reason
                  addMembersDropDownError errors

            tpl.selected_members.set []
            tpl.select_mode.set false

      return

    "keyup .members-search-input": (e, template) ->
      value = $(e.target).val().trim()

      if _.isEmpty value
        return template.members_filter.set(null)
      else
        template.members_filter.set(value)

      return

    "keydown .members-search-input": (e, tpl) ->
      if $(".member-invite-dropdown").hasClass "slideIn" # Button is visible
        if e.keyCode == 40 # Down
            $(".invite-dropdown-btn").focus()

        if e.keyCode == 13
          tpl.switch_to_invite_mode()

      return

    "keydown .invite-dropdown-btn": (e, tpl) ->
      if e.keyCode == 38 # Up
        input = $(".members-search-input")[0]
        input.focus()

        setTimeout -> # Move caret at the end of the text inside the input
          input.setSelectionRange(input.value.length, input.value.length)
        , 0


      if e.keyCode == 13
        tpl.switch_to_invite_mode()

      return

    "click .members-dropdown-menu": (e, tpl) ->
      e.stopPropagation() # need to avoit close dropdown on click

      return

    "click .member-settings-dropdown-btn": (e, tpl) ->
      $(".member-settings-dropdown-menu").removeClass "open"
      $dropdown = $(e.target).parents(".member-settings-dropdown")
      $dropdown_menu = $dropdown.find(".member-settings-dropdown-menu")
      $dropdown_menu.addClass "open"

      return

    "click .members-dropdown-list": (e, tpl) ->
      $dropdown = $(e.target).parents(".member-settings-dropdown")

      if not $dropdown[0]
        $(".member-settings-dropdown-menu").removeClass "open"

      return

    "click .member-settings-dropdown-menu .dropdown-item": (e, tpl) ->
      $(e.target).parents(".member-settings-dropdown-menu").removeClass "open"

      return

    "click .member-invite-btn-js": (e, tpl) ->
      tpl.switch_to_invite_mode()

      return

    "click .members-dropdown-invite .go-back": (e, tpl) ->
      tpl.invite_mode.set false

      return

  Template.admin_member_item.helpers module.template_helpers
  Template.regular_member_item.helpers module.template_helpers
  Template.guest_member_item.helpers module.template_helpers
  Template.enrollment_pending_member.helpers module.template_helpers

  Template.enrollment_pending_member.events
    "click .edit-enrolled": (e, tpl) ->
      ProjectPageDialogs.editEnrolledMember @user_id, {add_as_guest: tpl.data.is_guest}

      $(".dropdown-menu.show").removeClass("show") # Hide the dropdown, since after editing, the user will have to-reopen the dropdown for the user new details to show (it'll look like a bug if we won't do it).

      return
