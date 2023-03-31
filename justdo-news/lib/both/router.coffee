_.extend JustdoNews.prototype,
  setupRouter: ->
    Router.route "/justdo-news", ->
      @render "justdo_news_page"

      return
    ,
      name: "justdo_news_page"

    return
