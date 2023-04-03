_.extend JustdoNews.prototype,
  setupRouter: ->
    Router.route "/news", ->
      APP.justdo_news.redirectToMostRecentNewsPage()
      return
    ,
     name: "news"

    Router.route "/news/:news_version", ->
      version = @params.news_version.toLowerCase()
      if not APP.justdo_news.getNewsIdIfExists(version)?
        APP.justdo_news.redirectToMostRecentNewsPage()

      @render "news"
      @layout "single_frame_layout"
      return
    ,
      name: "news_with_version"

    Router.route "/news/:news_version/:news_template", ->
      version = @params.news_version.toLowerCase()
      news_template = @params.news_template
      if news_template is "main"
        @redirect "/news/#{version}"

      if not APP.justdo_news.getTemplateForNewsIfExists(version, news_template)?
        APP.justdo_news.redirectToMostRecentNewsPage()

      @render "news"
      @layout "single_frame_layout"
      return
    ,
      name: "news_with_version_and_template"

    return
