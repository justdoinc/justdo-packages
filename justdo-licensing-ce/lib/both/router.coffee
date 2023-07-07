_.extend JustdoLicensingCe.prototype,
  setupRouter: ->
    Router.route "/justdo-licensing-ce", ->
      @render "justdo_licensing_ce_page"

      return
    ,
      name: "justdo_licensing_ce_page"

    if Meteor.isClient
      APP.executeAfterAppLibCode ->
        JD.registerPlaceholderItem "justdo-licensing-ce",
          data:
            html: """
              <a class="text-dark text-uppercase d-flex align-items-center text-decoration-none" href="/justdo-licensing-ce">
                <div class="menu-item-icon bg-primary p-2 text-white shadow-sm rounded-sm">
                  <i class="fa fa-fw fa-handshake-o icons" aria-hidden="true"></i>
                </div>
                #{JustdoLicensingCe.custom_page_label}
              </a>
            """

          domain: "drawer-pages"
          position: 100

          listingCondition: ->
            return true

    return