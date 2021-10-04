_.extend JustdoCertMaintainer.prototype,
  setupRouter: ->
    Router.route "/justdo-cert-maintainer", ->
      @render "justdo_cert_maintainer_page"

      return
    ,
      name: "justdo_cert_maintainer_page"

    if Meteor.isClient
      APP.executeAfterAppLibCode ->
        JD.registerPlaceholderItem "justdo-cert-maintainer",
          data:
            html: """
              <a class="text-dark text-uppercase d-flex align-items-center text-decoration-none" href="/justdo-cert-maintainer">
                <div class="menu-item-icon bg-primary p-2 text-white shadow-sm rounded-sm">
                  <i class="fa fa-fw fa-handshake-o icons" aria-hidden="true"></i>
                </div>
                #{JustdoCertMaintainer.custom_page_label}
              </a>
            """

          domain: "drawer-pages"
          position: 100

          listingCondition: ->
            return true

    return