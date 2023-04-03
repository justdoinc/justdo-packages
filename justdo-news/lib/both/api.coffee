_.extend JustdoNews.prototype,
  _bothImmediateInit: ->
    # @_bothImmediateInit runs before the specific env's @_immediateInit()

    # Add here code that should run, in the Server and Client, during the JS
    # tick in which we create the object instance.

    @setupRouter()

    return

  _bothDeferredInit: ->
    # @_bothDeferredInit runs before the specific env's @_deferredInit()

    # Add here code that should run, in the Server and Client, after the JS
    # tick in which we created the object instance.

    if @destroyed
  registerNewsCategory: (category) ->
    if _.has @news, category
      return

    @news[category] = []

    for route_path, {route_name, routingFunction} of @_generateRouteFunctionForNewsCategory category
      Router.route route_path, routingFunction, {name: route_name}

    if Meteor.isClient
      @category_dep.changed()

    return

  _generateRouteFunctionForNewsCategory: (category) ->
    underscored_category = category.replace /-/g, "_"

    routes =
      "/#{category}":
        route_name: "#{underscored_category}_page"
        routingFunction: ->
          APP.justdo_news.redirectToMostRecentNewsPageByCategoryOrFallback category
          return
      "/#{category}/:news_id":
        route_name: "#{underscored_category}_page_with_news_id"
        routingFunction: ->
          news_id = @params.news_id.toLowerCase()

          if not APP.justdo_news.getNewsIdIfExists(category, news_id)?
            APP.justdo_news.redirectToMostRecentNewsPageByCategoryOrFallback category

          @render "news"
          @layout "single_frame_layout"
          return
      "/#{category}/:news_id/:news_template":
        route_name: "#{underscored_category}_page_with_news_id_and_template"
        routingFunction: ->
          news_id = @params.news_id.toLowerCase()
          news_template = @params.news_template

          if news_template is "main"
            @redirect "/#{category}/#{news_id}"

          if not APP.justdo_news.getTemplateForNewsIfExists(category, news_id, news_template)?
            APP.justdo_news.redirectToMostRecentNewsPageByCategoryOrFallback category

          @render "news"
          @layout "single_frame_layout"
          return

    return routes

      return

    return
