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

  Template.members_dropdown_menu.onCreated ->
    @members_filter = new ReactiveVar null

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

  Template.members_dropdown_menu.events
    "click .show-add-members-dialog": (e, tpl) ->
      ProjectPageDialogs.showMemberDialog()

      return

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
                addMembersDropDownError err.reason

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
  Template.guest_member_item.helpers module.template_helpers
  Template.enrollment_pending_member.helpers module.template_helpers

  Template.enrollment_pending_member.events
    "click .edit-enrolled": (e, tpl) ->
      ProjectPageDialogs.editEnrolledMember @user_id, {add_as_guest: tpl.data.is_guest}

      $(".dropdown-menu.show").removeClass("show") # Hide the dropdown, since after editing, the user will have to-reopen the dropdown for the user new details to show (it'll look like a bug if we won't do it).


      return
