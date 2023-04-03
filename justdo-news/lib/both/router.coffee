_.extend JustdoNews.prototype,
  setupRouter: ->
    Router.route "/news", ->
      APP.justdo_news.redirectToMostRecentNewsPage()
      return
    ,
     name: "news"

    Router.route "/news/:news_id", ->
      news_id = @params.news_id.toLowerCase()
      if not APP.justdo_news.getNewsIdIfExists(news_id)?
        APP.justdo_news.redirectToMostRecentNewsPage()

      @render "news"
      @layout "single_frame_layout"
      return
    ,
      name: "news_with_id"

    Router.route "/news/:news_id/:news_template", ->
      news_id = @params.news_id.toLowerCase()
      news_template = @params.news_template
      if news_template is "main"
        @redirect "/news/#{news_id}"

      if not APP.justdo_news.getTemplateForNewsIfExists(version, news_template)?
        APP.justdo_news.redirectToMostRecentNewsPage()

      @render "news"
      @layout "single_frame_layout"
      return
    ,
      name: "news_page_with_id_and_template"

    return
