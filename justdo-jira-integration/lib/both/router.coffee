_.extend JustdoJiraIntegration.prototype,
  setupRouter: ->
    # Router.route "/justdo-jira-integration", ->
    #   @render "justdo_jira_integration_page"

    #   return
    # ,
    #   name: "justdo_jira_integration_page"

    # if Meteor.isClient
    #   APP.executeAfterAppLibCode ->
    #     JD.registerPlaceholderItem "justdo-jira-integration",
    #       data:
    #         html: """
    #           <a class="text-dark text-uppercase d-flex align-items-center text-decoration-none" href="/justdo-jira-integration">
    #             <div class="menu-item-icon bg-primary p-2 text-white shadow-sm rounded-sm">
    #               <i class="fa fa-fw fa-handshake-o icons" aria-hidden="true"></i>
    #             </div>
    #             #{JustdoJiraIntegration.custom_page_label}
    #           </a>
    #         """

    #       domain: "drawer-pages"
    #       position: 100

    #       listingCondition: ->
    #         return true

    return