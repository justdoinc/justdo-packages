_.extend JustdoProjectsDashboard.prototype,
  setupRouter: ->
    Router.route '/justdo-projects-dashboard', ->
      @render 'justdo_projects_dashboard_page'

      return
    ,
      name: 'justdo_projects_dashboard_page'

    if Meteor.isClient
      APP.executeAfterAppLibCode ->
        JD.registerPlaceholderItem "justdo-projects-dashboard",
          data:
            html: """
              <a class="text-dark text-uppercase d-flex align-items-center text-decoration-none" href="/justdo-projects-dashboard">
                <div class="menu-item-icon bg-primary p-2 text-white shadow-sm rounded-sm">
                  <i class="fa fa-fw fa-handshake-o icons" aria-hidden="true"></i>
                </div>
                #{JustdoProjectsDashboard.custom_page_label}
              </a>
            """

          domain: "drawer-pages"
          position: 100

          listingCondition: ->
            return true

    return