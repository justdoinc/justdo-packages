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
    
    @showLicenseExpirationReminderIfExpiring()

    return

  _registerDrawerLicenseInfo: ->
    if not LICENSE_RV?
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
    if not (license = LICENSE_RV?.get())?
      return false
    
    if not is_site_admin?
      is_site_admin = @isCurrentUserSiteAdmin()

    show_expiring_headsup_threshold = JustdoSiteAdmins.license_expire_headsup_day_for_non_site_admins
    if is_site_admin
      show_expiring_headsup_threshold = JustdoSiteAdmins.license_expire_headsup_day_for_site_admins

    days_until_license_expire = (new Date(license.expire_on) - new Date()) / (1000 * 60 * 60 * 24)
    return days_until_license_expire < show_expiring_headsup_threshold

  showLicenseExpirationReminderIfExpiring: ->
    if @client_type isnt "web-app"
      return

    if not LICENSE_RV?
      return
      
    Tracker.autorun (computation) =>
      if not LICENSE_RV.get()?
        return

      if @isLicenseExpiring()
        @showLicenseExpirationReminder()
      
      computation.stop()
      return

    return

  showLicenseExpirationReminder: ->
    if not LICENSE_RV?
      return

    is_user_site_admin = @isCurrentUserSiteAdmin()
    is_expiring = @isLicenseExpiring()

    modal_template = JustdoHelpers.renderTemplateInNewNode Template.license_info_modal, {is_expiring}
    title = TAPi18n.__ "license_info_license_information"
    if is_expiring
      title = TAPi18n.__ "license_info_your_license_is_about_to_expire"
    bootbox_options = 
      size: "extra-large"
      className: "bootbox-new-design"
      title: title
      rtl_ready: true
      message: modal_template.node

    if is_user_site_admin and is_expiring
      bootbox_options.buttons =
        renew:
          label: TAPi18n.__ "license_info_renew_license"
          className: "btn-primary"
          callback: ->
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
  _getMembersPageUserRemarks: (user) ->
    remarks = []

    # Excluded remarks can co-exist with site-admin or deactivated, but not expiring/expired.
    is_user_excluded = false
    if APP.accounts.isUserExcluded?(user)
      is_user_excluded = true
      remarks.push """<span class="badge badge-success rounded-0 mr-1">Excluded</span>"""

    if APP.justdo_site_admins.isUserSiteAdmin(user)
      remarks.push """<span class="badge badge-primary rounded-0 mr-1">Site Admin</span>"""

    if APP.justdo_site_admins.isProxyUser?(user)
      remarks.push """<span class="badge badge-info rounded-0 mr-1">Proxy User</span>"""

    if (is_user_deactivated = APP.accounts.isUserDeactivated(user))
      remarks.push """<span class="badge badge-secondary rounded-0 mr-1">Deactivated</span>"""

    if (license = LICENSE_RV?.get())?
      is_user_licensed = user.licensed or is_user_deactivated or is_user_excluded
      license_trial_period = license.trial_cutoff
      new_user_grace_period = license.new_user_grace_period

      if not is_user_licensed and (license_trial_period? or new_user_grace_period?)
        # If user isn't licensed, check if the furthest of user grace period and license grace period has passed
        user_grace_period_ends = moment().subtract(1, "days")
        if new_user_grace_period?
          user_grace_period_ends = moment(user.createdAt).add(new_user_grace_period, "days")
        
        license_trial_period_ends = moment().subtract(1, "days")
        if license_trial_period?
          license_trial_period_ends = moment(license_trial_period, "YYYY-MM-DD")

        if (furthest_grace_period = moment(Math.max user_grace_period_ends, license_trial_period_ends)) >= moment()
          is_user_licensed = true
          remarks.push """<span class="badge badge-warning rounded-0 mr-1">License expires on #{furthest_grace_period.format(JustdoHelpers.getUserPreferredDateFormat())}</span>"""

      if not is_user_licensed
        remarks.push """<span class="badge badge-danger rounded-0 mr-1">License expired</span>"""

    return remarks.join(" ")