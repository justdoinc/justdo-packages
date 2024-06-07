_.extend JustdoNews.prototype,
  _bothImmediateInit: ->
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
    if _.isEmpty category or not _.isString category
      throw @_error "invalid-argument"

    if _.has @news, category
      throw @_error "news-category-already-exists"

    @news[category] = []

    if @register_news_routes
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
          APP.justdo_i18n?.forceLtrForRoute "#{underscored_category}_page"

          APP.justdo_news.redirectToMostRecentNewsPageByCategoryOrFallback category
          return
      "/#{category}/:news_id":
        route_name: "#{underscored_category}_page_with_news_id"
        routingFunction: ->
          APP.justdo_i18n?.forceLtrForRoute "#{underscored_category}_page_with_news_id"

          news_id = @params.news_id.toLowerCase()

          if not APP.justdo_news.getNewsIdIfExists(category, news_id)?
            APP.justdo_news.redirectToMostRecentNewsPageByCategoryOrFallback category

          @render "news"
          @layout "single_frame_layout"
          return
      "/#{category}/:news_id/:news_template":
        route_name: "#{underscored_category}_page_with_news_id_and_template"
        routingFunction: ->
          APP.justdo_i18n?.forceLtrForRoute "#{underscored_category}_page_with_news_id_and_template"

          news_id = @params.news_id.toLowerCase()
          news_template = @params.news_template

          if news_template is "main"
            @redirect "/#{category}/#{news_id}"

          if not APP.justdo_news.getNewsTemplateIfExists(category, news_id, news_template)?
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
    template_data:
      label: "Template Data Array"
      type: Object
      blackbox: true
      optional: true
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
    bootbox_title:
      label: "Custom bootbox title"
      type: String
      optional: true
    bootbox_classes:
      label: "Custom bootbox classes"
      type: String
      optional: true
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

    if not _.has @news, category
      throw @_error "news-category-not-found"

    @news[category].push news_obj
    @news[category] = _.sortBy(@news[category], "date").reverse() # Ensures the first element is the newest
    if Meteor.isClient
      @news_dep.changed()
    return

  getNewsByIdOrAlias: (category, news_id_or_alias) ->
    if Meteor.isClient
      @category_dep.depend()
      @news_dep.depend()
      
    if not category? or not news_id_or_alias?
      return

    return _.find @news[category], (news) -> 
      news_aliases = news.aliases or []
      return (news._id is news_id_or_alias) or (news_id_or_alias in news_aliases)

  getAllRegisteredCategories: -> _.keys @news
