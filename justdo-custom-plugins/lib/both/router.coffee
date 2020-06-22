_.extend JustdoCustomPlugins.prototype,
  setupRouter: ->
    Router.route '/justdo-custom-plugins', ->
      @render 'justdo_custom_plugins_page'

      return
    ,
      name: 'justdo_custom_plugins_page'

    if Meteor.isClient
      APP.executeAfterAppLibCode ->
        JD.registerPlaceholderItem "justdo-custom-plugins",
          data:
            html: """
              <a class="text-dark text-uppercase d-flex align-items-center text-decoration-none" href="/justdo-custom-plugins">
                <div class="menu-item-icon bg-primary p-2 text-white shadow-sm rounded-sm">
                  <i class="fa fa-fw fa-handshake-o icons" aria-hidden="true"></i>
                </div>
                #{JustdoCustomPlugins.custom_page_label}
              </a>
            """

          domain: "drawer-pages"
          position: 100

          listingCondition: ->
            return true

    return