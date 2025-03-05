Template.site_admin_user_dropdown_edit_proxy_user.helpers
  eligibleToShow: ->
    return APP.accounts.isProxyUser @user_data

Template.site_admin_user_dropdown_edit_proxy_user.events
  "click .edit-proxy-user": (e, tpl) ->
    @dropdown.closeDropdown()

    APP.projects.ensureUsersPublicBasicUsersInfoLoaded @user_data._id, (err, res) =>
      if err?
        JustdoSnackbar.show
          text: "Failed to load user details: \n#{err.reason}"
        return

      ProjectPageDialogs.editEnrolledMember @user_data._id, {}, (err, res) =>
        if err?
          JustdoSnackbar.show
            text: "Failed to edit proxy user: \n#{err.reason}"
          return
        
        # Update the row to reflect the changes
        user = Meteor.users.findOne @user_data._id, {fields: {profile: 1, emails: 1, is_proxy: 1}}
        $display_name_and_avatar_cell = @dropdown.$connected_element.siblings("td:first")
        $display_name_and_avatar_cell.find(".justdo-avatar").attr "src", JustdoAvatar.showUserAvatarOrFallback user
        $display_name_and_avatar_cell.find(".display-name").text JustdoHelpers.displayName user

        return

      return

    return
