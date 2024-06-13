_.extend JustdoI18nRoutes.prototype,
  _immediateInit: ->
    @_setupLangRedirectRules()
    @_setupPreloadLangsPredicate()

    return

  _deferredInit: ->
    if @destroyed
      return

    # Defined in methods.coffee
    @_setupMethods()

    # Defined in publications.coffee
    @_setupPublications()

    # Defined in collections-hooks.coffee
    @_setupCollectionsHooks()

    # Defined in collections-indexes.coffee
    @_ensureIndexesExists()

    return

  _setupLangRedirectRules: ->
    WebApp.connectHandlers.use "/lang", (req, res, next) =>
      # Important: this isn't iron-router, this is the WebApp layer, happens before the iron-router.
      #
      # This handler will have no effect in case there's no need to redirect
      #
      # It takes care of the following cases:
      #
      #   1. Redirecting to the default language if the language tag is the default one (/en/pricing -> /pricing)
      #   2. Redirecting to the proper language tag if the language tag is supported but case mismatches (e.g. /zh-tw/pricing -> /zh-TW/pricing)

      url_segments = _.filter req.url.split("/"), (url_segment) -> not _.isEmpty url_segment
      if _.isEmpty url_segments
        next()
        return

      url_lang = url_segments.shift()
      lang_tag = @getLangTagIfSupported url_lang
      path = "/#{url_segments.join "/"}"

      # Redirect to url without /lang/:lang_tag if lang_tag is default_lang
      if lang_tag is JustdoI18n.default_lang
        res.writeHead 301,
          Location: "#{path}"
        res.end()
        return

      # Redirect to the proper /lang/:lang_tag if lang_tag is supported but case mismatches (e.g. zh-tw > zh-TW)
      if lang_tag? and (lang_tag isnt url_lang)
        res.writeHead 301,
          Location: req.originalUrl.replace url_lang, lang_tag
        res.end()
        return

      next()

      return

  _setupPreloadLangsPredicate: ->
    APP.justdo_i18n.registerLangsToPreloadPredicate (req) => @getUrlLang req
    return

  getUrlLang: (req) ->
    url_segments = _.filter req.url.split("/"), (url_segment) -> not _.isEmpty url_segment

    if _.isEmpty url_segments
      return

    if url_segments.shift() isnt "lang"
      return

    url_lang = url_segments.shift()
    lang_tag = @getLangTagIfSupported url_lang
    return lang_tag
