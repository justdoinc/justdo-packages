_.extend JustdoNews.prototype,
  _immediateInit: ->
    @_setupConnectHandlers()
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

  _setupConnectHandlers: ->
    if not @register_news_routes
      return

    URL = JustdoHelpers.getURL()

    redirectToNewsUrl = (http_code, url_obj, res) ->
      res.writeHead http_code,
        Location: url_obj
      res.end()
      return
    WebApp.connectHandlers.use (req, res, next) =>
      url = req.url
      if APP.justdo_i18n_routes?
        data = APP.justdo_i18n_routes.getStrippedPathAndLangFromReq req
        url = data.processed_path
        lang = data.lang_tag

      # The construction of url_obj is necessary to keep the search params and other parts of the url intact when redirecting
      url_obj = new URL url, JustdoHelpers.getRootUrl()

      {news_category, news_id, news_template} = @getNewsParamFromPath url_obj.pathname

      # If news_category isn't registered, skip.
      # Note that this is a middleware. news_category could be any path (not just /news)
      if not (news_category_obj = @getCategory news_category)?
        next()
        return
      
      # By this point we know news_category exists and is valid.
      most_recent_news_id = news_category_obj.news[0]._id
      
      # If there's no news_id, redirect to the most recent news under the category
      if _.isEmpty news_id
        redirect_url = "/#{news_category}/#{most_recent_news_id}"
        if lang?
          redirect_url = APP.justdo_i18n_routes.i18nPath redirect_url, lang

        url_obj.pathname = redirect_url
        redirectToNewsUrl 302, url_obj, res
        return
      
      # If news_id or news_template is invalid, return 404
      is_news_id_invalid = true
      if (news = @getNewsByIdOrAlias(news_category, news_id))?
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
      
      # If the news_id is default, redirect to the path without news_template
        redirect_url = "/#{news_category}/#{news_id}"
        if lang?
          redirect_url = APP.justdo_i18n_routes.i18nPath redirect_url, lang
          
        url_obj.pathname = redirect_url
        redirectToNewsUrl 301, url_obj, res
      if is_alias or @isDefaultNewsTemplate(news_template)
        return

      # Everything is valid. Continue.
      next()

      return

    return
