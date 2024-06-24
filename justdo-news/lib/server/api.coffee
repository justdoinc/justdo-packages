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
    redirectToNewsUrl = (res, category, news_id, lang) ->
      url = "/#{category}/#{news_id}"
      if lang?
        url = "/#{JustdoI18nRoutes.langs_url_prefix}/#{lang}#{url}"
      res.writeHead 302,
        Location: "/#{category}/#{news_id}"
      res.end()
      return
    WebApp.connectHandlers.use (req, res, next) =>
      url = APP.justdo_i18n_routes?.getPathWithoutLangPrefix(req.url) or req.url
      lang = APP.justdo_i18n_routes?.getUrlLangFromReq(req)

      [news_category, news_id, news_template] = _.filter url.split("/"), (url_segment) -> not _.isEmpty url_segment

      # If news_category isn't registered, skip.
      # Note that this is a middleware. news_category could be any valid paths.
      if not (most_recent_news_id = @getMostRecentNewsIdUnderCategory news_category)
        next()
        return
      
      # By this point we know news_category exists and is valid.
      
      # If there's no news_id or news_id isn't registered under news_category, redirect to the most recent news under the category
      if (_.isEmpty news_id) or not (news_doc = @getNewsByIdOrAlias news_category, news_id)?
        redirectToNewsUrl res, news_category, most_recent_news_id, lang
        return
      
      # If news_template is invalid, redirect to the most recent news under the category
      if (not _.isEmpty news_template) and not (news_template = _.find(news_doc.templates, (template) -> template._id is news_template))?
        redirectToNewsUrl res, news_category, most_recent_news_id, lang
        return

      # Everything is valid. Continue.
      next()

      return

    return
