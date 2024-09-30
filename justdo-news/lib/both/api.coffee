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

  _registerCategoryOptionsSchema: new SimpleSchema
    template:
      label: "News category template"
      type: String
      defaultValue: JustdoNews.default_news_category_template
    translatable:
      label: "News category translatable"
      type: Boolean
      defaultValue: true
    title_in_url:
      label: "Append title to URL"
      type: Boolean
      defaultValue: false
  registerCategory: (category, options) ->
    if _.isEmpty category or not _.isString category
      throw @_error "invalid-argument"

    if @isCategoryExists category
      throw @_error "news-category-already-exists"

    {cleaned_val} =
      JustdoHelpers.simpleSchemaCleanAndValidate(
        @_registerCategoryOptionsSchema,
        options or {},
        {self: @, throw_on_error: true}
      )
    options = cleaned_val
    options.news = []

    @news[category] = options

    if @register_news_routes
      for route_path, {routingFunction, route_options} of @_generateRouteFunctionForCategory category
        if options.translatable and APP.justdo_i18n_routes?
          # Register i18n route for news
          APP.justdo_i18n_routes?.registerRoutes {path: route_path, routingFunction: routingFunction, route_options: route_options}
        else
          Router.route route_path, routingFunction, route_options
        
    if Meteor.isClient
      @category_dep.changed()

    return

  isCategoryExists: (category) ->
    return _.has @news, category
  
  requireCategoryExists: (category) ->
    if not @isCategoryExists category
      throw @_error "news-category-not-found"
    
    return true
  
  getCategory: (category) ->
    if Meteor.isClient
      @category_dep.depend()

    return @news[category]

  getAllNewsByCategory: (category) ->
    if Meteor.isClient
      @category_dep.depend()
      @news_dep.depend()

    if @isCategoryExists category
      return JSON.parse(JSON.stringify(@getCategory(category).news))
    return []

  getMostRecentNewsObjUnderCategory: (category) ->
    if Meteor.isClient
      @category_dep.depend()
      @news_dep.depend()

    return @getCategory(category)?.news?[0]

  _generateRouteFunctionForCategory: (category) ->
    self = @
    @requireCategoryExists category
    news_category_options = Tracker.nonreactive => @getCategory category
    underscored_category = category.replace /-/g, "_"

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
          title_in_url: news_category_options.title_in_url
          mapGenerator: ->
            ret = 
              url: "/#{category}"
              canonical_to: self.getCanonicalNewsPath({category, news: self.getMostRecentNewsObjUnderCategory(category)})
            yield ret
            return
      "/#{category}/:news_id":
        routingFunction: ->
          news_id = @params.news_id.toLowerCase()

          if not self.getNewsByIdOrAlias(category, news_id)?
            self.redirectToMostRecentNewsPageByCategoryOrFallback category

          self.redirectToCanonicalPathIfNecessary category, news_id

          @render news_category_options.template
          @layout "single_frame_layout"
          return
        route_options:
          name: "#{underscored_category}_page_with_news_id"
          translatable: news_category_options.translatable
          title_in_url: news_category_options.title_in_url
          metadata: metadata
          mapGenerator: ->
            for news_doc in self.getAllNewsByCategory category
              ret = 
                url: self.getCanonicalNewsPath {category, news: news_doc}
              yield ret
            return
          i18nPath: (path, lang) ->
            {news_id} = Router.routes[@name].params path
            return self.getCanonicalNewsPath {lang, category, news: news_id}

      "/#{category}/:news_id/:news_template":
        routingFunction: ->
          news_id = @params.news_id.toLowerCase()
          news_template = @params.news_template

          if self.isDefaultNewsTemplate news_template
            @redirect "/#{category}/#{news_id}"

          if not self.getNewsTemplateIfExists(category, news_id, news_template)?
            self.redirectToMostRecentNewsPageByCategoryOrFallback category
          
          self.redirectToCanonicalPathIfNecessary category, news_id, news_template

          @render news_category_options.template
          @layout "single_frame_layout"
          return
        route_options:
          name: "#{underscored_category}_page_with_news_id_and_template"
          translatable: news_category_options.translatable
          title_in_url: news_category_options.title_in_url
          metadata: metadata
          mapGenerator: ->
            for news_doc in self.getAllNewsByCategory category
              for template_obj in news_doc.templates
                news_template_id = template_obj._id
                if not self.isDefaultNewsTemplate news_template_id
                  ret = 
                    url: self.getCanonicalNewsPath {category, news: news_doc, template: news_template_id}
                  yield ret
            return
          i18nPath: (path, lang) ->
            {news_id, news_template} = Router.routes[@name].params path
            return self.getCanonicalNewsPath {lang, category, news: news_id, template: news_template}

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
    subtitle:
      label: "News Subtitle"
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
    if not (_.find news_obj?.templates, (template_obj) => @isDefaultNewsTemplate template_obj._id)?
      throw @_error "no-main-template"

    @requireCategoryExists category

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
    
    {news_id_or_alias} = @extractNewsIdAndTitleFromUrlComponent(news_id_or_alias)

    is_alias = false
    news_doc = _.find @getCategory(category).news, (news) -> 
      if news._id is news_id_or_alias
        return true

      news_aliases = news.aliases or []
      if news_id_or_alias in news_aliases
        is_alias = true
        return true

      return false
    
    if not news_doc?
      return
    
    return {news_doc: news_doc, is_alias: is_alias}
    
  getNewsTemplateIfExists: (category, news_id_or_alias, template_name) ->
    if not (news = @getNewsByIdOrAlias(category, news_id_or_alias)?.news_doc)?
      return
    return _.find news.templates, (template_obj) -> template_obj._id is template_name

  getAllRegisteredCategories: -> _.keys @news

  getNewsParamFromPath: (path) ->    
    # Remove the search part of the path
    path = JustdoHelpers.getNormalisedUrlPathnameWithoutSearchPart path
    if APP.justdo_i18n_routes?
      path = APP.justdo_i18n_routes.getPathWithoutLangPrefix path

    [news_category, news_id, news_template] = _.filter path.split("/"), (path_segment) -> not _.isEmpty path_segment
    return {news_category, news_id, news_template}
  
  getNewsPageTitle: (news_doc, template) ->
    if _.isEmpty template
      template = JustdoNews.default_news_template
    
    return _.find(news_doc?.templates, (template_obj) -> template_obj._id is template)?.page_title or news_doc.title

  getI18nCanonicalNewsPath: (options) ->
    {category, news_id, template, lang} = options

    if Meteor.isServer and _.isEmpty lang
      throw @_error "missing-argument", "options.lang must be provided when calling this method on the server"
    
    news_path = @getCanonicalNewsPath options

    return APP.justdo_i18n_routes?.i18nPath(news_path, lang) or news_path

  # NOTE: url_component should only contain the news_id part with the title (e.g. v5-0--justdo-ai)
  extractNewsIdAndTitleFromUrlComponent: (url_component) ->
    url_component = url_component?.split(JustdoNews.url_title_separator)
    if _.isEmpty url_component
      return
    
    ret = 
      news_id_or_alias: url_component[0]
      url_title: url_component[1]
    
    return ret
  
  isDefaultNewsTemplate: (template_id) -> template_id is JustdoNews.default_news_template

  # NOTE: this method uses the Iron Router and should not be used in the middleware level
  redirectToCanonicalPathIfNecessary: (category, news_id, template) ->
    # Server-side redirection should happen in the middleware level
    if Meteor.isServer
      return

    canonical_news_url = Tracker.nonreactive => @getI18nCanonicalNewsPath {category, news_id, template}
    canonical_news_id = @getNewsParamFromPath(canonical_news_url).news_id
    
    if news_id isnt canonical_news_id
      Router.go canonical_news_url, {news_id: canonical_news_id}, {replaceState: true}        
    
    return
  
# Originally, the JustdoNews package was created to be a news package, but we
# ended up using it as a CRM package. So, we're going to create some aliases
# to make it easier to use the CRM features.
_.extend JustdoNews.prototype,
  getAllItemsByCategory: JustdoNews.prototype.getAllNewsByCategory
  getMostRecentItemObjUnderCategory: JustdoNews.prototype.getMostRecentNewsObjUnderCategory
  registerItem: JustdoNews.prototype.registerNews
  getItemByIdOrAlias: JustdoNews.prototype.getNewsByIdOrAlias
  isDefaultItemTemplate: JustdoNews.prototype.isDefaultNewsTemplate