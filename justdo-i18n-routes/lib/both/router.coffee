_.extend JustdoI18nRoutes.prototype,
  setupRouter: ->
    Router.route "/justdo-i18n-routes", ->
      @render "justdo_i18n_routes_page"

      return
    ,
      name: "justdo_i18n_routes_page"

    if Meteor.isClient
      APP.executeAfterAppLibCode ->
        JD.registerPlaceholderItem "justdo-i18n-routes",
          data:
            html: """
              <a class="text-dark text-uppercase d-flex align-items-center text-decoration-none" href="/justdo-i18n-routes">
                <div class="menu-item-icon bg-primary p-2 text-white shadow-sm rounded-sm">
                  <i class="fa fa-fw fa-handshake-o icons" aria-hidden="true"></i>
                </div>
                #{JustdoI18nRoutes.custom_page_label}
              </a>
            """

          domain: "drawer-pages"
          position: 100

          listingCondition: ->
            return true

    return