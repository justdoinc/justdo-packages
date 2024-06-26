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
    
    redirectToNewsUrl = (res, category, news_id, lang) ->
      url = "/#{category}/#{news_id}"
      if lang?
        url = APP.justdo_i18n_routes.i18nPath url, lang
      res.writeHead 302,
        Location: url
      res.end()
      return
    WebApp.connectHandlers.use (req, res, next) =>
      lang = APP.justdo_i18n_routes?.getUrlLangFromReq(req)

      {news_category, news_id, news_template} = @getNewsParamFromReq req

      # If news_category isn't registered, skip.
      # Note that this is a middleware. news_category could be any path (not just /news)
      if not (most_recent_news_id = @getMostRecentNewsIdUnderCategory news_category)
        next()
        return
      
      # By this point we know news_category exists and is valid.
      
      # If there's no news_id, redirect to the most recent news under the category
      if _.isEmpty news_id
        redirectToNewsUrl res, news_category, most_recent_news_id, lang
        return
      
      # If news_id or news_template is invalid, return 404
      is_news_id_invalid = true
      if (news_doc = @getNewsByIdOrAlias news_category, news_id)?
        is_news_id_invalid = false

        # The template is the last part of the url (e.g. other-updates here: /news/justdo-ai/other-updates )
        # If news_template isn't provided in the url, we don't care if it's valid or not.
        is_news_template_invalid = news_template? and not _.find(news_doc.templates, (template) -> template._id is news_template)?
      if is_news_id_invalid or is_news_template_invalid
        res.writeHead 404
        # XXX We should probably return a nicely-styled static 404 page here, like the one on Youtube
        res.end "404 Not Found"
        return

      # Everything is valid. Continue.
      next()

      return

    return

  getNewsParamFromReq: (req) ->
    url = APP.justdo_i18n_routes?.getPathWithoutLangPrefix(req.url) or req.url
    [news_category, news_id, news_template] = _.filter url.split("/"), (url_segment) -> not _.isEmpty url_segment
    return {news_category, news_id, news_template}