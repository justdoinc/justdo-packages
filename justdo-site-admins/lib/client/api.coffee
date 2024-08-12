_.extend JustdoSiteAdmins.prototype,
  _immediateInit: ->
    @registerGlobalTemplateHelpers()
    @_setupMembersPage()
    @site_admin_page_position = 100

    return

  _deferredInit: ->
    if @destroyed
      return

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

