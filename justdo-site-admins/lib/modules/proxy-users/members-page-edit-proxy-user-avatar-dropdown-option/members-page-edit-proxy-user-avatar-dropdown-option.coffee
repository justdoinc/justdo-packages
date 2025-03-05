Template.site_admin_user_dropdown_edit_proxy_user_avatar.helpers
  eligibleToShow: ->
    return APP.accounts.isProxyUser(@user_data) and JustdoAvatar.isAvatarNotSetOrBase64Svg(@user_data)

Template.site_admin_user_dropdown_edit_proxy_user_avatar.events
  "click .edit-proxy-user-avatar": (e, tpl) ->
    @dropdown.closeDropdown()

    APP.accounts.editUserAvatarColor @user_data._id, (err) =>
      if err?
        JustdoSnackbar.show
          text: "Failed to edit proxy user avatar: \n#{err.reason}"
        return
      
      # Update the row to reflect the changes
      user = Meteor.users.findOne @user_data._id, {fields: {profile: 1, emails: 1, is_proxy: 1}}
      $display_name_and_avatar_cell = @dropdown.$connected_element.siblings("td:first")
      $display_name_and_avatar_cell.find(".justdo-avatar").attr "src", JustdoAvatar.showUserAvatarOrFallback user

      return

    return