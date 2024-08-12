_.extend JustdoSiteAdmins.prototype,
  setupRouter: ->
    self = @

    if @client_type is "web-app"
      route_name = "justdo_site_admins_page"

      Router.route "/justdo-site-admins", ->
        APP.justdo_i18n.forceLtrForRoute route_name
        
        if self.isCurrentUserSiteAdmin()
          @render "justdo_site_admins_page",
            data: ->
              return {view_name: "members"}
        else
          @render "justdo_site_admins_page"

        return
      ,
        name: route_name

    if Meteor.isClient
      APP.executeAfterAppLibCode ->
        # JD isn't defined on the landing page
        JD?.registerPlaceholderItem "justdo-site-admins",
          data:
            html: """
              <a class="d-flex align-items-center text-decoration-none" href="/justdo-site-admins">
                <div class="menu-item-icon bg-primary p-2 text-white shadow-sm rounded-sm">
                  <i class="fa fa-fw fa-handshake-o icons" aria-hidden="true"></i>
                </div>
                #{JustdoSiteAdmins.custom_page_label}
              </a>
            """

          domain: "drawer-pages"
          position: 100

          listingCondition: ->
            return APP.justdo_site_admins.siteAdminFeatureEnabled("admins-list-public") or self.isCurrentUserSiteAdmin()

    return
