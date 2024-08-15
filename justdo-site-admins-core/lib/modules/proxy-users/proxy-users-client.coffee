_.extend JustdoSiteAdmins.modules["proxy-users"],
  clientDeferredInit: ->
    JD.registerPlaceholderItem "site-admins-members-dropdown-toggle-proxy-user",
      position: 200
      domain: "site-admins-members-dropdown-items"
      data:
        template: "site_admin_user_dropdown_toggle_proxy_user"
