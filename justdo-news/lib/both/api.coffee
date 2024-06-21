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
      for route_path, {routingFunction, route_options} of @_generateRouteFunctionForNewsCategory category
        if APP.justdo_i18n_routes?
          # Register i18n route for news
          APP.justdo_i18n_routes?.registerRoutes {path: route_path, routingFunction: routingFunction, route_options: route_options}
        else
          Router.route route_path, routingFunction, route_options
        
    if Meteor.isClient
      @category_dep.changed()

    return

  getAllNewsByCategory: (category) ->
    if Meteor.isClient
      @category_dep.depend()
      @news_dep.depend()

    if _.has @news, category
      return JSON.parse(JSON.stringify(@news[category]))
    return []

  getMostRecentNewsIdUnderCategory: (category) ->
    if Meteor.isClient
      @category_dep.depend()
      @news_dep.depend()

    return @news[category]?[0]?._id

  _generateRouteFunctionForNewsCategory: (category) ->
    self = @
    underscored_category = category.replace /-/g, "_"

    routes =
      "/#{category}":
        routingFunction: ->
          APP.justdo_i18n?.forceLtrForRoute "#{underscored_category}_page"

          self.redirectToMostRecentNewsPageByCategoryOrFallback category
          return
        route_options:
          name: "#{underscored_category}_page"
          mapGenerator: ->
            ret = 
              url: "/#{category}"
              canonical_to: "/#{category}/#{self.getMostRecentNewsIdUnderCategory category}"
            yield ret
            return
      "/#{category}/:news_id":
        routingFunction: ->
          APP.justdo_i18n?.forceLtrForRoute "#{underscored_category}_page_with_news_id"

          news_id = @params.news_id.toLowerCase()

          if not self.getNewsIdIfExists(category, news_id)?
            self.redirectToMostRecentNewsPageByCategoryOrFallback category

          @render "news"
          @layout "single_frame_layout"
          return
        route_options:
          name: "#{underscored_category}_page_with_news_id"
          mapGenerator: ->
            for news_doc in self.getAllNewsByCategory category
              ret = 
                url: "/#{category}/#{news_doc._id}"
              yield ret
            return
      "/#{category}/:news_id/:news_template":
        route_name: "#{underscored_category}_page_with_news_id_and_template"
        routingFunction: ->
          APP.justdo_i18n?.forceLtrForRoute "#{underscored_category}_page_with_news_id_and_template"

          news_id = @params.news_id.toLowerCase()
          news_template = @params.news_template

          if news_template is "main"
            @redirect "/#{category}/#{news_id}"

          if not self.getNewsTemplateIfExists(category, news_id, news_template)?
            self.redirectToMostRecentNewsPageByCategoryOrFallback category

          @render "news"
          @layout "single_frame_layout"
          return
        route_options:
          name: "#{underscored_category}_page_with_news_id_and_template"
          mapGenerator: ->
            for news_doc in self.getAllNewsByCategory category
              for template_obj in news_doc.templates
                if (news_template_id = template_obj._id) isnt "main"
                  ret = 
                    url: "/#{category}/#{news_doc._id}/#{news_template_id}"
                  yield ret
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
