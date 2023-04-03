_.extend JustdoNews.prototype,
  _bothImmediateInit: ->
    # On server, @news only stores category, but not the news_obj.
    @news = {}

    if Meteor.isClient
      @news_dep = new Tracker.Dependency()
      @category_dep = new Tracker.Dependency()

    return

  _bothDeferredInit: ->
    if @destroyed
      return

    return

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

  _newsTemplateSchema = new SimpleSchema
    _id:
      label: "Template ID"
      type: String
    template_name:
      label: "Template Name"
      type: String
    name:
      label: "Template Title"
      type: String
  _registerNewsSchema: new SimpleSchema
    _id:
      label: "News ID"
      type: String
    title:
      label: "News Title"
      type: String
    aliases:
      label: "News Aliases"
      type: [String]
      optional: true
    date:
      label: "News Date"
      type: String
    templates:
      label: "News Template Array"
      type: [Object]
    "templates.$":
      label: "News Template Object"
      type: _newsTemplateSchema
  registerNews: (category, news_obj) ->
    {cleaned_val} =
      JustdoHelpers.simpleSchemaCleanAndValidate(
        @_registerNewsSchema,
        news_obj or {},
        {self: @, throw_on_error: true}
      )
    news_obj = cleaned_val
    if not (_.find news_obj?.templates, (template_obj) -> template_obj._id is "main")?
      throw @_error "no-main-template"

    @registerNewsCategory category

    if Meteor.isServer
      return

    @news[category].push news_obj
    @news[category] = _.sortBy(@news[category], "date").reverse() # Ensures the first element is the newest
    @news_dep.changed()
    return
