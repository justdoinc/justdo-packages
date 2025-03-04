Template.site_admin_user_dropdown_toggle_proxy_user.helpers
  eligibleToShow: ->
    # Hide this option if the user is either deactivated or site admin
    return not @user_data.deactivated and not @user_data.site_admin?.is_site_admin

  isProxyUser: -> APP.accounts.isProxyUser @user_data

Template.site_admin_user_dropdown_toggle_proxy_user.events
  "click .toggle-proxy-user": (e, tpl) ->
    @dropdown.closeDropdown()

    if APP.accounts.isProxyUser @user_data
      method_name = "saUnsetAsProxyUsers"
    else
      method_name = "saSetAsProxyUsers"

    Meteor.call method_name, @user_data._id, (err) =>
      if err?
        JustdoSnackbar.show
          text: err.reason or "Failed to set #{@user_data.first_name} #{@user_data.last_name} as proxy user."
        return
      all_site_users = @all_site_users_rv.get()
      user_index = _.findIndex all_site_users, (user) => user._id is @user_data._id
      if method_name is "saSetAsProxyUsers"
        all_site_users[user_index].is_proxy = true
        delete all_site_users[user_index].profile.profile_pic
      else
        all_site_users[user_index].is_proxy = false
      @all_site_users_rv.set all_site_users

      return

    return
    
  "click .edit-proxy-user": (e, tpl) ->
    @dropdown.closeDropdown()
    
    # Only site admins can edit proxy users
    unless APP.justdo_site_admins.isCurrentUserSiteAdmin()
      return
      
    # Call the edit proxy user dialog
    ProjectPageDialogs.editProxyUser @user_data._id, (err, result) =>
      if err?
        JustdoSnackbar.show
          text: err.reason or "Failed to update proxy user."
        return
        
      # Update the user in the UI if successful
      if result?
        all_site_users = @all_site_users_rv.get()
        user_index = _.findIndex all_site_users, (user) => user._id is @user_data._id
        
        # Update the name in the UI
        if result.profile?.first_name?
          all_site_users[user_index].profile.first_name = result.profile.first_name
          
        if result.profile?.last_name?
          all_site_users[user_index].profile.last_name = result.profile.last_name
          
        # Update email if it changed
        if result.email?
          all_site_users[user_index].emails[0].address = result.email
          
        @all_site_users_rv.set all_site_users
        
        # Show success message
        JustdoSnackbar.show
          text: "Proxy user updated successfully"
          type: "success"
          
      return
      
    return
