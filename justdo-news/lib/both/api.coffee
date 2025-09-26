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
    disable_title_in_url_for_default_lang:
      label: "Disable title in URL for default language"
      type: Boolean
      defaultValue: false
    auto_redirect_to_most_recent_news:
      label: "Auto redirect to most recent news"
      type: Boolean
      defaultValue: true
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

    category_route_name = "#{underscored_category}_page"
    category_with_news_id_route_name = "#{underscored_category}_page_with_news_id"
    category_with_news_id_and_template_route_name = "#{underscored_category}_page_with_news_id_and_template"

    metadata =
      title_i18n: (path_without_lang, lang) ->
        if APP.justdo_seo?
          path_without_lang = APP.justdo_seo.getPathWithoutHumanReadableParts path_without_lang
        {news_id, news_template} = self.getNewsParamFromPath path_without_lang

        if (page_title = self.getNewsPageTitle category, news_id, news_template)?
          return TAPi18n.__ page_title, {}, lang

        return APP.justdo_seo.getDefaultPageTitle lang
      description_i18n: (path_without_lang, lang) ->
        if APP.justdo_seo?
          path_without_lang = APP.justdo_seo.getPathWithoutHumanReadableParts path_without_lang
        {news_id, news_template} = self.getNewsParamFromPath path_without_lang

        news_template_doc = self.getNewsTemplateIfExists category, news_id, news_template
        if (page_description = news_template_doc?.page_description)?
          return TAPi18n.__ page_description, {}, lang

        return APP.justdo_seo.getDefaultPageDescription lang
      preview_image: (path_without_lang) ->
        if APP.justdo_seo?
          path_without_lang = APP.justdo_seo.getPathWithoutHumanReadableParts path_without_lang
        {news_id} = self.getNewsParamFromPath path_without_lang

        news_template_doc = self.getNewsTemplateIfExists category, news_id, JustdoNews.default_news_template

        return news_template_doc?.template_data?.news_array?[0]?.media_url

    getI18nKeyToDetermineSupportedLangs = (path_without_hrp_and_lang) ->
      # For a given path, return the default_news_template_key_to_determine_supported_langs i18n key from the news template
      # for justdo-i18n-routes to determine the supported languages for the given path.
      {news_id, news_template} = self.getNewsParamFromPath path_without_hrp_and_lang

      if not news_id?
        return

      news_template_doc = self.getNewsTemplateIfExists category, news_id, news_template
      return news_template_doc?[JustdoNews.default_news_template_key_to_determine_supported_langs]

    routes =
      "/#{category}":
        routingFunction: ->
          if news_category_options.auto_redirect_to_most_recent_news
            self.redirectToMostRecentNewsPageByCategoryOrFallback category
          else
            @render news_category_options.template
            @layout "single_frame_layout"
          return
        route_options:
          name: category_route_name
          translatable: news_category_options.translatable
          mapGenerator: ->
            ret = 
              url: "/#{category}"
            if news_category_options.auto_redirect_to_most_recent_news
              ret.canonical_to = "/#{category}/#{self.getMostRecentNewsObjUnderCategory(category)._id}"
            else
              ret.canonical_to = "/#{category}"
            yield ret
            return
      "/#{category}/:news_id":
        routingFunction: ->
          news_id = @params.news_id.toLowerCase()
          if APP.justdo_seo?
            news_id = APP.justdo_seo.getPathWithoutHumanReadableParts news_id

          if not self.getNewsIdIfExists(category, news_id)?
            self.redirectToMostRecentNewsPageByCategoryOrFallback category

          @render news_category_options.template
          @layout "single_frame_layout"
          return
        route_options:
          name: category_with_news_id_route_name
          translatable: news_category_options.translatable
          getI18nKeyToDetermineSupportedLangs: getI18nKeyToDetermineSupportedLangs
          mapGenerator: ->
            for news_doc in self.getAllNewsByCategory category
              ret = 
                url: "/#{category}/#{news_doc._id}"
              yield ret
            return
          metadata: metadata
          hrp_supported: news_category_options.title_in_url
          getCanonicalHrpURL: (path_without_hrp_and_lang, lang) ->
            {news_id} = Router.routes[category_with_news_id_route_name].params path_without_hrp_and_lang

            path = "/#{category}/#{news_id}"

            is_default_lang = lang is JustdoI18n.default_lang
            disable_title_in_url_for_default_lang = news_category_options.disable_title_in_url_for_default_lang
            should_add_hrp = not (is_default_lang and disable_title_in_url_for_default_lang)

            if should_add_hrp and (news_title = self.getNewsPageTitle category, news_id)?
              path += @getHRPForI18nKey news_title, lang

            return path
            
      "/#{category}/:news_id/:news_template":
        routingFunction: ->
          news_id = @params.news_id.toLowerCase()
          news_template = @params.news_template
          if APP.justdo_seo?
            news_id = APP.justdo_seo.getPathWithoutHumanReadableParts news_id
            news_template = APP.justdo_seo.getPathWithoutHumanReadableParts news_template

          if self.isDefaultNewsTemplate news_template
            @redirect "/#{category}/#{news_id}"

          if not self.getNewsTemplateIfExists(category, news_id, news_template)?
            self.redirectToMostRecentNewsPageByCategoryOrFallback category

          @render news_category_options.template
          @layout "single_frame_layout"
          return
        route_options:
          name: category_with_news_id_and_template_route_name
          translatable: news_category_options.translatable
          getI18nKeyToDetermineSupportedLangs: getI18nKeyToDetermineSupportedLangs
          mapGenerator: ->
            for news_doc in self.getAllNewsByCategory category
              for template_obj in news_doc.templates
                news_template_id = template_obj._id
                if not self.isDefaultNewsTemplate news_template_id
                  ret = 
                    url: "/#{category}/#{news_doc._id}/#{news_template_id}"
                  yield ret
            return
          metadata: metadata
          hrp_supported: news_category_options.title_in_url
          getCanonicalHrpURL: (path_without_hrp_and_lang, lang) ->
            {news_id, news_template} = Router.routes[category_with_news_id_and_template_route_name].params path_without_hrp_and_lang

            path = "/#{category}/#{news_id}"

            is_default_lang = lang is JustdoI18n.default_lang
            disable_title_in_url_for_default_lang = news_category_options.disable_title_in_url_for_default_lang
            should_add_hrp = not (is_default_lang and disable_title_in_url_for_default_lang)

            if should_add_hrp and (news_title = self.getNewsPageTitle category, news_id)?
              path += @getHRPForI18nKey news_title, lang

            if news_template? and not self.isDefaultNewsTemplate news_template
              path += "/#{news_template}"

            return path
            
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
    page_hrp:
      label: "Template Page Hrp"
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
    tags:
      label: "News Tags"
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
  
  getNewsByTag: (category, tag) ->
    if not category? or not tag?
      return

    @requireCategoryExists category

    return _.filter @getCategory(category).news, (news) -> 
      if not news.tags?
        return false

      return tag in news.tags
    
  getNewsTemplateIfExists: (category, news_id_or_alias, template_name) ->
    if not template_name?
      template_name = JustdoNews.default_news_template

    if not (news = @getNewsByIdOrAlias(category, news_id_or_alias)?.news_doc)?
      return

    return _.find news.templates, (template_obj) -> template_obj._id is template_name

  getAllRegisteredCategories: -> _.keys @news

  getNewsParamFromPath: (path) ->    
    # Remove the search part of the path
    path = JustdoHelpers.getNormalisedUrlPathnameWithoutSearchPart path

    [news_category, news_id, news_template] = _.filter path.split("/"), (path_segment) -> not _.isEmpty path_segment
    return {news_category, news_id, news_template}

  isDefaultNewsTemplate: (template_id) -> template_id is JustdoNews.default_news_template

  getNewsPageTitle: (category, news_id_or_alias, template) ->
    # Returns the page_title for the combination of category, news and template
    #
    # We return an empty string if the news item doesn't exist or if the template doesn't exist.
    template_doc = @getNewsTemplateIfExists(category, news_id_or_alias, template)
    return template_doc?.page_title or ""
  
  getNewsPageHrp: (category, news_id_or_alias, template) ->
    # Returns the page_hrp, or page_title as fallback, for the combination of category, news and template
    # 
    # If the news item doesn't exist or if the template doesn't exist, it will return an empty string.
    template_doc = @getNewsTemplateIfExists(category, news_id_or_alias, template)
    return template_doc?.page_hrp or @getNewsPageTitle(category, news_id_or_alias, template)

# Originally, the JustdoNews package was created to be a news package, but we
# ended up using it as a CRM package. So, we're going to create some aliases
# to make it easier to use the CRM features.
_.extend JustdoNews.prototype,
  getAllItemsByCategory: JustdoNews.prototype.getAllNewsByCategory
  getMostRecentItemObjUnderCategory: JustdoNews.prototype.getMostRecentNewsObjUnderCategory
  registerItem: JustdoNews.prototype.registerNews
  getItemByIdOrAlias: JustdoNews.prototype.getNewsByIdOrAlias
  getItemsByTag: JustdoNews.prototype.getNewsByTag
  isDefaultItemTemplate: JustdoNews.prototype.isDefaultNewsTemplate