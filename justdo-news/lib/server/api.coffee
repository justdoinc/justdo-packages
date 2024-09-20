_.extend JustdoNews.prototype,
  _immediateInit: ->
    @_setupConnectHandlers()
    @_registerPostmapGenerator()
    return

  _deferredInit: ->
    if @destroyed
      return

    # Defined in methods.coffee
    @_setupMethods()

    # Defined in publications.coffee
    @_setupPublications()

    # Defined in collections-indexes.coffee
    @_ensureIndexesExists()

    return

  _registerPostmapGenerator: ->
    APP.justdo_i18n_routes.registerPostMapGenerator "news-title-in-url",
      predicate: (translated_map_obj) -> translated_map_obj.route.options?.title_in_url
      generator: (translated_map_obj, lang) =>
        path = translated_map_obj.url

        has_canonical_to = translated_map_obj.canonical_to?
        if has_canonical_to
          path = translated_map_obj.canonical_to

        path_without_lang = APP.justdo_i18n_routes.getPathWithoutLangPrefix path

        {news_category, news_id, news_template} = @getNewsParamFromPath path_without_lang
        news_doc = @getNewsByIdOrAlias(news_category, news_id).news_doc
        page_title = @getNewsPageTitle news_doc, news_template
        existing_url_title = @extractNewsIdAndTitleFromUrlComponent(news_id).url_title

        updated_path = path.replace "--#{existing_url_title}", @newsTitleToUrlComponent(page_title, lang)

        if has_canonical_to
          translated_map_obj.canonical_to = updated_path
        else
          translated_map_obj.url = updated_path

        return

  _setupConnectHandlers: ->
    if not @register_news_routes
      return

    URL = JustdoHelpers.getURL()

    # This middleware is responsible for the following use cases:
    #   1. Redirect to the most recent news under news_category if received_news_id is not provided using 302
    #   2. Return 404 if news_category exists, but received_news_id or news_template is invalid
    #   3. Redirect news url back to canonical url (e.g. /news/v5-0-x--justdo-ai > /news/v5-0) using 301
    # For all redirects, this middleware is expected to preserve the lang and other parts of url (e.g. search params)
    WebApp.connectHandlers.use (req, res, next) =>
      original_url = req.originalUrl
      # The construction of original_url_obj is necessary to keep the search params and other parts of the url intact when redirecting
      original_url_obj = new URL original_url, JustdoHelpers.getRootUrl()
      if APP.justdo_i18n_routes?
        data = APP.justdo_i18n_routes.getStrippedPathAndLangFromReq req
        url_without_lang = data.processed_path
        url_without_lang_obj = new URL url_without_lang, JustdoHelpers.getRootUrl()
        lang = data.lang_tag or JustdoI18n.default_lang

      {news_category, news_id: received_news_id, news_template} = @getNewsParamFromPath url_without_lang_obj?.pathname or original_url_obj.pathname

      # If news_category isn't registered, skip.
      # Note that this is a middleware. news_category could be any path (not just /news)
      if not (news_category_obj = @getCategory news_category)?
        next()
        return

      # By this point we know news_category exists and is valid.

      # redirectToNewsUrl handles appending title to url and i18n the path, if needed, and performs redirect.
      redirectToNewsUrl = (http_code, news_doc) =>
        news_id = news_doc._id

        redirect_url = @getI18nCanonicalNewsPath {lang, category: news_category, news: news_id, template: news_template}
        
        # No need to perform redirect if everything's the same
        if redirect_url is original_url_obj.pathname
          return
        
        original_url_obj.pathname = redirect_url

        res.writeHead http_code,
          Location: original_url_obj
        res.end()
        return

      # If there's no received_news_id, redirect to the most recent news under the category
      if _.isEmpty received_news_id
        most_recent_news_doc = news_category_obj.news[0]
        most_recent_news_id = most_recent_news_doc._id
        redirectToNewsUrl 302, most_recent_news_doc
        return
      
      # Extract news_id from url component with title (e.g. v5-0--justdo-ai > v5-0)
      {news_id_or_alias} = @extractNewsIdAndTitleFromUrlComponent received_news_id

      # If news_id or news_template is invalid, return 404
      is_news_id_invalid = true
      if (news = @getNewsByIdOrAlias(news_category, news_id_or_alias))?
        {news_doc, is_alias} = news
        news_id = news_doc._id
        is_news_id_invalid = false

        # The template is the last part of the url (e.g. other-updates here: /news/justdo-ai/other-updates )
        # If news_template isn't provided in the url, we don't care if it's valid or not.
        is_news_template_invalid = news_template? and not _.find(news_doc.templates, (template) -> template._id is news_template)?
      if is_news_id_invalid or is_news_template_invalid
        res.writeHead 404
        # XXX We should probably return a nicely-styled static 404 page here, like the one on Youtube
        res.end "404 Not Found"
        return
      
      isnt_canonical_news_path = decodeURI(original_url_obj.pathname) isnt @getI18nCanonicalNewsPath {lang, category: news_category, news: news_id, template: news_template}
      # If the news_id is default, redirect to the path without news_template
      if is_alias or @isDefaultNewsTemplate(news_template) or isnt_canonical_news_path
        redirectToNewsUrl 301, news_doc
        return

      # Everything is valid. Continue.
      next()

      return

    return
