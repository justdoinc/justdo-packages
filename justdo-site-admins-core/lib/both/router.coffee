_.extend JustdoSiteAdminsCore.prototype,
  setupRouter: ->
    Router.route "/justdo-site-admins-core", ->
      @render "justdo_site_admins_core_page"

      return
    ,
      name: "justdo_site_admins_core_page"

    if Meteor.isClient
      APP.executeAfterAppLibCode ->
        JD.registerPlaceholderItem "justdo-site-admins-core",
          data:
            html: """
              <a class="text-dark text-uppercase d-flex align-items-center text-decoration-none" href="/justdo-site-admins-core">
                <div class="menu-item-icon bg-primary p-2 text-white shadow-sm rounded-sm">
                  <i class="fa fa-fw fa-handshake-o icons" aria-hidden="true"></i>
                </div>
                #{JustdoSiteAdminsCore.custom_page_label}
              </a>
            """

          domain: "drawer-pages"
          position: 100

          listingCondition: ->
            return true

    return