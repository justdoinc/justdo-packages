_.extend JustdoNewProjectTemplates.prototype,
  setupRouter: ->
    Router.route "/justdo-new-project-templates", ->
      @render "justdo_new_project_templates_page"

      return
    ,
      name: "justdo_new_project_templates_page"

    if Meteor.isClient
      APP.executeAfterAppLibCode ->
        JD.registerPlaceholderItem "justdo-new-project-templates",
          data:
            html: """
              <a class="text-dark text-uppercase d-flex align-items-center text-decoration-none" href="/justdo-new-project-templates">
                <div class="menu-item-icon bg-primary p-2 text-white shadow-sm rounded-sm">
                  <i class="fa fa-fw fa-handshake-o icons" aria-hidden="true"></i>
                </div>
                #{JustdoNewProjectTemplates.custom_page_label}
              </a>
            """

          domain: "drawer-pages"
          position: 100

          listingCondition: ->
            return true

    return