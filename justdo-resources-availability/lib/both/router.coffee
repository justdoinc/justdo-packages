_.extend JustdoResourcesAvailability.prototype,
  setupRouter: ->
    Router.route '/justdo-resources-availability', ->
      @render 'justdo_resources_availability_page'

      return
    ,
      name: 'justdo_resources_availability_page'

    if Meteor.isClient
      APP.executeAfterAppLibCode ->
        APP.modules.main.registerPlaceholderItem "justdo-resources-availability",
          data:
            html: """
              <a class="text-dark text-uppercase d-flex align-items-center text-decoration-none" href="/justdo-resources-availability">
                <div class="menu-item-icon bg-primary p-2 text-white shadow-sm rounded-sm">
                  <i class="fa fa-fw fa-handshake-o icons" aria-hidden="true"></i>
                </div>
                #{JustdoResourcesAvailability.custom_page_label}
              </a>
            """

          position: 100
          domain: "drawer-pages"

          listingCondition: ->
            return true

    return
