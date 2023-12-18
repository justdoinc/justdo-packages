_.extend JustdoVimeoLoader.prototype,
  setupRouter: ->
    Router.route "/justdo-vimeo-loader", ->
      @render "justdo_vimeo_loader_page"

      return
    ,
      name: "justdo_vimeo_loader_page"

    if Meteor.isClient
      APP.executeAfterAppLibCode ->
        JD.registerPlaceholderItem "justdo-vimeo-loader",
          data:
            html: """
              <a class="text-dark text-uppercase d-flex align-items-center text-decoration-none" href="/justdo-vimeo-loader">
                <div class="menu-item-icon bg-primary p-2 text-white shadow-sm rounded-sm">
                  <i class="fa fa-fw fa-handshake-o icons" aria-hidden="true"></i>
                </div>
                #{JustdoVimeoLoader.custom_page_label}
              </a>
            """

          domain: "drawer-pages"
          position: 100

          listingCondition: ->
            return true

    return