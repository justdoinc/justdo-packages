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

  _registerNewsCategoryOptionsSchema: new SimpleSchema
    template:
      label: "News category template"
      type: String
      defaultValue: JustdoNews.default_news_category_template
    translatable:
      label: "News category translatable"
      type: Boolean
      defaultValue: true
  registerNewsCategory: (category, options) ->
    if _.isEmpty category or not _.isString category
      throw @_error "invalid-argument"

    if @isNewsCategoryExists category
      throw @_error "news-category-already-exists"

    {cleaned_val} =
      JustdoHelpers.simpleSchemaCleanAndValidate(
        @_registerNewsCategoryOptionsSchema,
        options or {},
        {self: @, throw_on_error: true}
      )
    options = cleaned_val
    options.news = []

    @news[category] = options

    if @register_news_routes
      for route_path, {routingFunction, route_options} of @_generateRouteFunctionForNewsCategory category
        if options.translatable and APP.justdo_i18n_routes?
          # Register i18n route for news
          APP.justdo_i18n_routes?.registerRoutes {path: route_path, routingFunction: routingFunction, route_options: route_options}
        else
          Router.route route_path, routingFunction, route_options
        
    if Meteor.isClient
      @category_dep.changed()

    return

  isNewsCategoryExists: (category) ->
    return _.has @news, category
  
  requireNewsCategoryExists: (category) ->
    if not @isNewsCategoryExists category
      throw @_error "news-category-not-found"
    
    return true
  
  getNewsCategoryOptions: (category) ->
    @requireNewsCategoryExists category
    return @news[category]

  getAllNewsByCategory: (category) ->
    if Meteor.isClient
      @category_dep.depend()
      @news_dep.depend()

    if @isNewsCategoryExists category
      return JSON.parse(JSON.stringify(@news[category].news))
    return []

  getMostRecentNewsIdUnderCategory: (category) ->
    if Meteor.isClient
      @category_dep.depend()
      @news_dep.depend()

    return @news[category]?.news?[0]?._id

  _generateRouteFunctionForNewsCategory: (category) ->
    self = @
    underscored_category = category.replace /-/g, "_"
    news_category_options = @getNewsCategoryOptions category

    metadata =
      title_i18n: (path_without_lang, lang) ->
        {news_id, new_template} = self.getNewsParamFromPath path_without_lang

        if not news_template?
          news_template = JustdoNews.default_news_template

        news_template_doc = self.getNewsTemplateIfExists category, news_id, news_template
        if (page_title = news_template_doc?.page_title)?
          return TAPi18n.__ page_title, {}, lang

        return APP.justdo_seo.getDefaultPageTitle lang
      description_i18n: (path_without_lang, lang) ->
        {news_id, new_template} = self.getNewsParamFromPath path_without_lang

        if not news_template?
          news_template = JustdoNews.default_news_template

        news_template_doc = self.getNewsTemplateIfExists category, news_id, news_template
        if (page_description = news_template_doc?.page_description)?
          return TAPi18n.__ page_description, {}, lang

        return APP.justdo_seo.getDefaultPageDescription lang
      preview_image: (path_without_lang) ->
        {news_id} = self.getNewsParamFromPath path_without_lang

        news_template_doc = self.getNewsTemplateIfExists category, news_id, JustdoNews.default_news_template

        return news_template_doc?.template_data?.news_array?[0]?.media_url

    routes =
      "/#{category}":
        routingFunction: ->
          self.redirectToMostRecentNewsPageByCategoryOrFallback category
          return
        route_options:
          name: "#{underscored_category}_page"
          translatable: news_category_options.translatable
          mapGenerator: ->
            ret = 
              url: "/#{category}"
              canonical_to: "/#{category}/#{self.getMostRecentNewsIdUnderCategory category}"
            yield ret
            return
      "/#{category}/:news_id":
        routingFunction: ->
          news_id = @params.news_id.toLowerCase()

          if not self.getNewsIdIfExists(category, news_id)?
            self.redirectToMostRecentNewsPageByCategoryOrFallback category

          @render news_category_options.template
          @layout "single_frame_layout"
          return
        route_options:
          name: "#{underscored_category}_page_with_news_id"
          translatable: news_category_options.translatable
          mapGenerator: ->
            for news_doc in self.getAllNewsByCategory category
              ret = 
                url: "/#{category}/#{news_doc._id}"
              yield ret
            return
          metadata: metadata

      "/#{category}/:news_id/:news_template":
        routingFunction: ->
          news_id = @params.news_id.toLowerCase()
          news_template = @params.news_template

          if news_template is JustdoNews.default_news_template
            @redirect "/#{category}/#{news_id}"

          if not self.getNewsTemplateIfExists(category, news_id, news_template)?
            self.redirectToMostRecentNewsPageByCategoryOrFallback category

          @render news_category_options.template
          @layout "single_frame_layout"
          return
        route_options:
          name: "#{underscored_category}_page_with_news_id_and_template"
          translatable: news_category_options.translatable
          mapGenerator: ->
            for news_doc in self.getAllNewsByCategory category
              for template_obj in news_doc.templates
                if (news_template_id = template_obj._id) isnt JustdoNews.default_news_template
                  ret = 
                    url: "/#{category}/#{news_doc._id}/#{news_template_id}"
                  yield ret
            return
          metadata: metadata

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
    page_title:
      label: "Template Page Title"
      type: String
      optional: true
    page_description:
      label: "Template Page Description"
      type: String
      optional: true
    h1:
      label: "Template H1"
      type: String
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
    if not (_.find news_obj?.templates, (template_obj) -> template_obj._id is JustdoNews.default_news_template)?
      throw @_error "no-main-template"

    @requireNewsCategoryExists category

    @news[category].news.push news_obj
    @news[category].news = _.sortBy(@news[category].news, "date").reverse() # Ensures the first element is the newest
    if Meteor.isClient
      @news_dep.changed()
    return

  getNewsByIdOrAlias: (category, news_id_or_alias) ->
    if Meteor.isClient
      @category_dep.depend()
      @news_dep.depend()
      
    if not category? or not news_id_or_alias?
      return

    return _.find @news[category].news, (news) -> 
      news_aliases = news.aliases or []
      return (news._id is news_id_or_alias) or (news_id_or_alias in news_aliases)
    
  getNewsTemplateIfExists: (category, news_id_or_alias, template_name) ->
    if not (news = @getNewsByIdOrAlias category, news_id_or_alias)
      return
    return _.find news.templates, (template_obj) -> template_obj._id is template_name

  getAllRegisteredCategories: -> _.keys @news

  getNewsParamFromPath: (path) ->    
    # Remove the search part of the path
    path = JustdoHelpers.getNormalisedUrlPathnameWithoutSearchPart path

    [news_category, news_id, news_template] = _.filter path.split("/"), (path_segment) -> not _.isEmpty path_segment
    return {news_category, news_id, news_template}