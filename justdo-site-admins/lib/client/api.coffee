_.extend JustdoSiteAdmins.prototype,
  _immediateInit: ->
    @registerGlobalTemplateHelpers()
    @_setupMembersPage()
    @_registerDrawerLicenseInfo()
    @_setupServerVitalsPage()
    @site_admin_page_position = 100

    return

  _deferredInit: ->
    if @destroyed
      return
    
    Tracker.autorun (computation) =>
      # Wait for user document to be available
      if not Meteor.user()?
        return
      @showLicenseExpirationReminderIfExpiring()
      computation.stop()
      return

    return

  _registerDrawerLicenseInfo: ->
    if not @isLicenseEnabledEnvironment()
      return

    JD.registerPlaceholderItem "license-info",
      data:
        template: "drawer_license_info"
      domain: "drawer-after-jd-version"
      position: 300
    
    return

  _setupMembersPage: ->
    @registerSiteAdminsPage "members", {template: "justdo_site_admin_members", position: 0}
    Tracker.autorun (computation) =>
      login_state = APP.login_state.getLoginState()
      login_state_sym = login_state[0]

      if (login_state_sym == "logged-in") and Meteor.user()?
        if @isUserSuperSiteAdmin Meteor.user()
          @registerSiteAdminsPage "members-ext", {template: "justdo_super_site_admin_members", title: "Members Ext.", position: 1}
        computation.stop()
      return
    return

  _setupServerVitalsPage: ->
    @registerSiteAdminsPage "system-info", {template: "justdo_site_admin_server_vitals", position: 100}
    return
  
  getLicense: -> 
    if not @isLicenseEnabledEnvironment()
      return {state: "none"}
    
    if not (license = LICENSE_RV.get())?
      return {state: "pending"}
    
    return {state: "active", license}

  isLicenseEnabledEnvironment: -> LICENSE_RV?

  registerSiteAdminsPage: (page_id, options) ->
    self = @

    check options.template, String
    check options.position, Match.Maybe Number

    dashed_page_id = page_id.replaceAll "_", "-"
    underscored_page_id = page_id.replaceAll "-", "_"
    route_name = "justdo_site_admins_page_#{underscored_page_id}"

    # Register route
    if @client_type is "web-app"
      route = options.route or "/justdo-site-admins/#{dashed_page_id}"
      if not _.isFunction(routeHandler = options.routeHandler)
        routeHandler = ->
          APP.justdo_i18n.forceLtrForRoute route_name

          if self.isCurrentUserSiteAdmin()
            @render "justdo_site_admins_page",
              data: ->
                return {view_name: dashed_page_id}
          else
            @render "justdo_site_admins_page"

          return
      Router.route route, routeHandler,
        name: route_name

    title = options.title or JustdoHelpers.ucFirst(page_id).replaceAll /(_|-)/g, " "

    if _.isNumber options?.position
      position = options.position
    else
      position = @site_admin_page_position
      @site_admin_page_position += 100

    # Register drawer item
    JD.registerPlaceholderItem "site-admins-#{dashed_page_id}-view",
      position: position
      domain: "site-admins-left-drawer"
      data:
        template: "justdo_site_admins_page_menu_item"
        template_data:
          id: dashed_page_id
          title: title
      listingCondition: options.listingCondition

    # Register page_id to template
    JustdoSiteAdmins.view_name_to_title_and_template_name.set dashed_page_id, {title, template_name: options.template}

    return

  isLicenseExpiring: (is_site_admin) ->
    if not (license = @getLicense().license)?
      return false
    
    if not is_site_admin?
      is_site_admin = @isCurrentUserSiteAdmin()

    show_expiring_headsup_threshold = JustdoSiteAdmins.license_expire_headsup_day_for_non_site_admins
    if is_site_admin
      show_expiring_headsup_threshold = JustdoSiteAdmins.license_expire_headsup_day_for_site_admins

    days_until_license_expire = (new Date(license.expire_on) - new Date()) / (1000 * 60 * 60 * 24)
    return days_until_license_expire < show_expiring_headsup_threshold

  isLicenseExpired: ->
    if not (license = @getLicense().license)?
      return false

    return new Date(license.expire_on) < new Date()
  
  getShutdownDate: ->
    if not (license = @getLicense().license)?
      return

    shutdown_date_moment = moment(license.expire_on, "YYYY-MM-DD")
    if (shutdown_grace = license.shutdown_grace)?
      shutdown_date_moment.add(license.shutdown_grace, "days")
    
    return shutdown_date_moment.format JustdoHelpers.getUserPreferredDateFormat()

  showLicenseExpirationReminderIfExpiring: ->
    if @client_type isnt "web-app"
      return

    if not @isLicenseEnabledEnvironment()
      return
      
    Tracker.autorun (computation) =>
      if not @getLicense().license?
        return

      if @isLicenseExpiring()
        @showLicenseExpirationReminder()
      
      computation.stop()
      return

    return

  showLicenseExpirationReminder: ->
    if not @isLicenseEnabledEnvironment()
      return

    is_user_site_admin = @isCurrentUserSiteAdmin()
    is_expiring = @isLicenseExpiring()
    is_expiring_soon = @isLicenseExpiring false
    is_expired = @isLicenseExpired()

    cur_user = Meteor.user()
    license = _.extend {}, @getLicense().license
    root_url = JustdoHelpers.getRootUrl()
    user_email = JustdoHelpers.getUserMainEmail cur_user
    license.domain = root_url
    request_data = 
      name: JustdoHelpers.displayName cur_user
      email: user_email
      message: "Hello. I would like to renew my site license.\n\nMy current license is \n#{JSON.stringify license, null, 2}.\n\nSent by #{user_email}"
      tz: moment.tz.guess()
      version: JustdoHelpers.getAppVersion()
      root_url: JustdoHelpers.getRootUrl()

    modal_template = JustdoHelpers.renderTemplateInNewNode Template.license_info_modal, {is_expiring, is_expiring_soon, is_expired, request_data}
    title = TAPi18n.__ "license_info_license_information"
    if is_expired
      title = TAPi18n.__ "license_info_your_license_has_expired"
    else if is_expiring
      title = TAPi18n.__ "license_info_your_license_is_about_to_expire"
    bootbox_options = 
      size: "extra-large"
      className: "bootbox-new-design"
      title: title
      rtl_ready: true
      message: modal_template.node

    if is_user_site_admin and (is_expiring or is_expired)
      redirectUserToContactPage = (query_params) ->
        APP.justdo_analytics.JA({cat: "renew-license", act: "redirected-to-contact-page"})
        url = new URL JustdoSiteAdmins.renew_license_fallback_endpoint, "https://justdo.com"
        for key, value of query_params
          url.searchParams.set key, value
        window.open url, "_blank"
        return

      bootbox_options.buttons =
        renew:
          label: TAPi18n.__ "license_info_renew_license"
          className: "btn-primary"
          callback: =>
            APP.justdo_analytics.JA({cat: "renew-license", act: "submit-attempt"})

            @renewalRequest request_data, (err, res) ->
              if err? or (res?.statusCode isnt 200)
                redirectUserToContactPage request_data
                APP.justdo_analytics.JA({cat: "renew-license", act: "failed"})
              else
                APP.justdo_analytics.JA({cat: "renew-license", act: "success"})
                dialog.modal("hide")
                
                bootbox.dialog
                  message: """
                    <svg class="jd-icon"><use xlink:href="/layout/icons-feather-sprite.svg#check"></use></svg>
                    <span><strong>#{TAPi18n.__ "thank_you"}.</strong><br>#{TAPi18n.__ "we_will_get_back_to_you_soon"}</span>
                  """
                  className: "bootbox-new-design bootbox-contact-successful"
                  closeButton: false
                  onEscape: ->
                    return true
                  buttons:
                    close: 
                      label: TAPi18n.__ "close"
                      callback: ->
                        return true
              return

            return
    else
      bootbox_options.buttons =
        ok:
          label: "OK"
          className: "btn-primary"
          callback: ->
            return

    dialog = bootbox.dialog bootbox_options

    return

  # NOTE: This method is meant to be used in the members page only
  _getMembersPageUserRemarks: (user, pre_computed_hard_licensed_users) ->
    remarks = []

    # Excluded remarks can co-exist with site-admin or deactivated, but not expiring/expired.
    if APP.justdo_site_admins.isUserSiteAdmin(user)
      remarks.push """<span class="badge badge-primary rounded-0 mr-1" title="Site admins have access to the site administration panel, allowing them to view system details and manage licenses.&#10;&#10;However, their role primarily focuses on user administration and does not automatically grant access to all tasks within the system.&#10;&#10;Each site admin must have a verified email address. If a site admin’s email address is changed, they will lose their site admin capabilities until the new email is verified.&#10;&#10;If the number of users exceeds the available licenses, site admins will be granted a license before any non-site admin users.">Site Admin</span>"""

    if APP.accounts.isProxyUser(user)
      title = "Proxies act as stand-in accounts for individuals who are not actively using or logging into JustDo. For example, you might assign tasks to a proxy to keep track of responsibilities for someone outside the system.&#10;&#10"
      if @getLicense()?.license?.is_sdk
        title += "Proxies are not counted against the available license total in SDK builds."
      else
        title += "Proxies are counted against the available license total."

      remarks.push """<span class="badge badge-info rounded-0 mr-1" title="#{title}">Proxy User</span>"""

    if (is_user_deactivated = APP.accounts.isUserDeactivated(user))
      remarks.push """<span class="badge badge-secondary rounded-0 mr-1" title="This user is deactivated and cannot log in to JustDo.&#10;Deactivated users do not count against the available license total.&#10;#{APP.accounts.getUserDeactivatedInfo(user)}">Deactivated</span>"""

    if @isLicenseEnabledEnvironment() and not is_user_deactivated
      user_license = @isUserLicensed user, pre_computed_hard_licensed_users

      if not user_license?.licensed
        remarks.push """<span class="badge badge-danger rounded-0 mr-1">License expired</span>"""
      else if user_license.type is "soft"
        soft_license_details = user_license.details
        if soft_license_details?.type is "excluded"
          remarks.push """<span class="badge badge-success rounded-0 mr-1">Excluded</span>"""
        else if soft_license_details?.type is "grace_period"
          grace_period_type = soft_license_details.grace_type
          human_readable_grade_period_expires = moment(soft_license_details.expires).format(JustdoHelpers.getUserPreferredDateFormat())

          if grace_period_type is "new_user"
            remarks.push """<span class="badge badge-warning rounded-0 mr-1" title="To prevent disruptions to normal business operations, JustDo grants new users a short, license-free trial period before they must obtain a proper license.&#10;&#10;This user requires a license, but will continue to enjoy the temporary, license-free access until the stated date.">New user grace period until #{human_readable_grade_period_expires}</span>"""
          if grace_period_type is "trial"
            remarks.push """<span class="badge badge-warning rounded-0 mr-1" title="Because the system is currently in its trial period, this user is granted access until the specified date.&#10;&#10;After that date, the user will need a valid license to continue using the system.">Trial period until #{human_readable_grade_period_expires}</span>"""

    return remarks.join(" ")