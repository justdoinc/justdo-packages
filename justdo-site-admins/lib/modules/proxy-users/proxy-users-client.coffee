_.extend JustdoSiteAdmins.modules["proxy-users"],
  clientDeferredInit: ->
    JD.registerPlaceholderItem "site-admins-members-dropdown-toggle-proxy-user",
      position: 200
      domain: "site-admins-members-dropdown-items"
      data:
        template: "site_admin_user_dropdown_toggle_proxy_user"
    
    JD.registerPlaceholderItem "site-admins-members-dropdown-edit-proxy-user",
      position: 400
      domain: "site-admins-members-dropdown-items"
      data:
        template: "site_admin_user_dropdown_edit_proxy_user"
      
    JD.registerPlaceholderItem "site-admins-members-dropdown-edit-proxy-user-avatar",
      position: 600
      domain: "site-admins-members-dropdown-items"
      data:
        template: "site_admin_user_dropdown_edit_proxy_user_avatar"
