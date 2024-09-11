_.extend JustdoSupportCenterData.prototype,
  setupRouter: ->
    Router.route "/justdo-support-center-data", ->
      @render "justdo_support_center_data_page"

      return
    ,
      name: "justdo_support_center_data_page"

    if Meteor.isClient
      APP.executeAfterAppLibCode ->
        JD.registerPlaceholderItem "justdo-support-center-data",
          data:
            html: """
              <a class="text-dark text-uppercase d-flex align-items-center text-decoration-none" href="/justdo-support-center-data">
                <div class="menu-item-icon bg-primary p-2 text-white shadow-sm rounded-sm">
                  <i class="fa fa-fw fa-handshake-o icons" aria-hidden="true"></i>
                </div>
                #{JustdoSupportCenterData.custom_page_label}
              </a>
            """

          domain: "drawer-pages"
          position: 100

          listingCondition: ->
            return true

    return