Template.site_admin_user_dropdown.onCreated ->
  # Template data is passed inside plugin-page-site-admin-user-dropdown.html
  # as items registered from modules doesn't have access to template data.
  JD.registerPlaceholderItem "site-admins-members-dropdown-toggle-deactivated-user",
    position: 0
    domain: "site-admins-members-dropdown-items"
    listingCondition: => not @data.user_data.site_admin?.is_site_admin and not @data.user_data.is_proxy
    data:
      template: "site_admin_user_dropdown_toggle_deactivted_user"

  JD.registerPlaceholderItem "site-admins-members-dropdown-toggle-site-admin",
    position: 100
    domain: "site-admins-members-dropdown-items"
    listingCondition: => not @data.user_data.deactivated and not @data.user_data.is_proxy
    data:
      template: "site_admin_user_dropdown_toggle_site_admin"

Template.site_admin_user_dropdown.helpers
  dropdownItems: -> JD.getPlaceholderItems "site-admins-members-dropdown-items"

  templateData: -> Template.instance().data

Template.site_admin_user_dropdown_toggle_deactivted_user.helpers
  isDeactivatedUser: -> @user_data.deactivated

Template.site_admin_user_dropdown_toggle_deactivted_user.events
  "click .toggle-deactivate-user": (e, tpl) ->
    @dropdown.closeDropdown()

    user_id = @user_data._id

    if APP.accounts.isUserDeactivated(@user_data)
      method = "reactivateUsers"
      warnings = [
        # "The JustDo memberships of this user will not be automatically recovered."
      ]
    else
      method = "deactivateUsers"
      warnings = [
        "The user will be removed from all #{if APP.justdo_orgs? then "Organizations and" else ""} JustDos"
        "The user will not be able to login."
        "If reactivated, will need to be manually added as a member again as needed."
        # Too techincal but accurate, original proposal
        # "The user will not be able to login."
        # "The user will be removed from all the JustDos in the Site."
        # "Even if the user is reactivated later, the JustDo memberships of this user will not be automatically recovered."
        # "The only case in which we won't remove the user from a JustDo is when the user is the only Admin of that JustDo. Yet, the user won't be able to operate on such JustDos while deactivated. Those JustDos will remain accessible to that user after reactivation."
      ]

    onSuccessProc = ->
      all_site_users = tpl.data.all_site_users_rv.get()

      user_index = _.findIndex all_site_users, (user) ->
        return user._id == user_id

      if method == "deactivateUsers"
        all_site_users[user_index].deactivated = true
      else
        all_site_users[user_index].deactivated = false

      tpl.data.all_site_users_rv.set(all_site_users)

      return

    message = ""
    if method == "deactivateUsers"
      message += "Are you sure you want to deactivate <b>#{JustdoHelpers.displayName(@user_data)}</b>'s account?"
    else
      message += "Are you sure you want to reactivate <b>#{JustdoHelpers.displayName(@user_data)}</b>'s account?"

    if not _.isEmpty(warnings)
      message += "<br><br><b>Important:</b><br><br><ul>"

      warnings.forEach (warning) ->
        message += "<li>#{warning}</li>"
      message += "</ul>"

    bootbox.confirm
      message: JustdoHelpers.xssGuard(message, {allow_html_parsing: true, enclosing_char: ""})
      className: "bootbox-new-design bootbox-new-design-simple-dialogs-default"
      closeButton: false

      callback: (result) ->
        if result
          APP.justdo_site_admins[method] user_id, (err, res) =>
            if err?
              JustdoSnackbar.show
                text: "Failed: #{err.reason}"

              return

            onSuccessProc()

            return

        return

    return

Template.site_admin_user_dropdown_toggle_site_admin.helpers
  isAdmin: -> APP.justdo_site_admins.isUserSiteAdmin @user_data

Template.site_admin_user_dropdown_toggle_site_admin.events
  "click .toggle-site-admin": (e, tpl) ->
    @dropdown.closeDropdown()

    user_id = @user_data._id

    if APP.justdo_site_admins.isUserSiteAdmin(@user_data)
      method = "unsetUsersAsSiteAdmins"
    else
      method = "setUsersAsSiteAdmins"

    onSuccessProc = ->
      all_site_users = tpl.data.all_site_users_rv.get()

      user_index = _.findIndex all_site_users, (user) ->
        return user._id == user_id

      if method == "unsetUsersAsSiteAdmins"
        delete all_site_users[user_index].site_admin
      else
        all_site_users[user_index].site_admin = {is_site_admin: true}

      tpl.data.all_site_users_rv.set(all_site_users)

      return

    message = ""

    if method == "unsetUsersAsSiteAdmins"
      message += "Are you sure you don't want <b>#{JustdoHelpers.displayName(@user_data)}</b> to remain a Site Admin?"
    else
      if not JustdoHelpers.isUserEmailsVerified @user_data
        JustdoSnackbar.show
          text: "Cannot promote user with non-verified email to site admin"
        return
        
      message += "Are you sure you want <b>#{JustdoHelpers.displayName(@user_data)}</b> to be a Site Admin?"

    list = _.compact(_.union.apply(_, _.map APP.justdo_site_admins.modules, (_module) -> _module[if method == "setUsersAsSiteAdmins" then "pre_set_as_admin_warnings" else "pre_unset_as_admin_warnings"]))

    if not _.isEmpty list
      message += "<br><br><b>Important:</b><br><br><ul><li>"

      message += list.join("</li><li>")

      message += "</li></ul>"

    bootbox.confirm
      message: JustdoHelpers.xssGuard(message, {allow_html_parsing: true, enclosing_char: ""})
      className: "bootbox-new-design bootbox-new-design-simple-dialogs-default"
      closeButton: false

      callback: (result) ->
        if result
          APP.justdo_site_admins[method] user_id, (err, res) =>
            if err?
              JustdoSnackbar.show
                text: "Failed: #{err.reason}"

              return

            onSuccessProc()

            return

        return

    return
