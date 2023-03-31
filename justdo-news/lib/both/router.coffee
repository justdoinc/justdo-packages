_.extend JustdoNews.prototype,
  setupRouter: ->
    Router.route "/justdo-news", ->
      @render "justdo_news_page"

      return
    ,
      name: "justdo_news_page"

    if Meteor.isClient
      APP.executeAfterAppLibCode ->
        JD.registerPlaceholderItem "justdo-news",
          data:
            html: """
              <a class="text-dark text-uppercase d-flex align-items-center text-decoration-none" href="/justdo-news">
                <div class="menu-item-icon bg-primary p-2 text-white shadow-sm rounded-sm">
                  <i class="fa fa-fw fa-handshake-o icons" aria-hidden="true"></i>
                </div>
                #{JustdoNews.custom_page_label}
              </a>
            """

          domain: "drawer-pages"
          position: 100

          listingCondition: ->
            return true

    return