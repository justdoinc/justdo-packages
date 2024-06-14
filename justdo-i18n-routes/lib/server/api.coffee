_.extend JustdoI18nRoutes.prototype,
  _immediateInit: ->
    @_setupLangRedirectRules()
    @_setupPreloadLangsDetectors()

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
    WebApp.connectHandlers.use JustdoI18nRoutes.langs_url_prefix, (req, res, next) =>
      # Important: this isn't iron-router, this is the WebApp layer, happens before the iron-router.
      #
      # This handler will have no effect in case there's no need to redirect
      #
      # It takes care of the following cases:
      #
      #   1. Redirecting to the default language if the language tag is the default one (/en/pricing -> /pricing)
      #   2. Redirecting to the proper language tag if the language tag is supported but case mismatches (e.g. /zh-tw/pricing -> /zh-TW/pricing)

      processed_lang_details = @getStrippedPathAndLangFromReq(req)

      if not processed_lang_details.lang?
        next()
        return

      if processed_lang_details.original_lang_tag?
        # Getting original_lang_tag means the lang tag was not correctly cased, redirect to the correct case
        res.writeHead 301,
          Location: req.originalUrl.replace processed_lang_details.original_lang_tag, processed_lang_details.lang_tag
        res.end()
        return

      if processed_lang_details.lang_tag is JustdoI18n.default_lang
        # We got a lang tag, but it's the default one, redirect to the path without the lang prefix
        res.writeHead 301,
          Location: processed_lang_details.processed_path
        res.end()
        return

      # Case was fine, and it's not the default lang, continue
      next()

      return

  _setupPreloadLangsDetectors: ->
    APP.justdo_i18n.registerLangsToPreloadDetector (req) => @getUrlLangFromReq req
    return

  getUrlLangFromReq: (req) -> @getStrippedPathAndLangFromReq(req).lang_tag
  getUrlLang: (absolute_path) -> @getUrlLangFromReq({originalUrl: absolute_path})

  getStrippedPathAndLangFromReq: (req) ->
    # processed_path won't include the lang prefix + lang *only* if a valid combination
    # of the form "/lang/:lang_tag" is received, otherwise it will return the originalUrl
    # of the req without any changes.
    #
    # Example:
    #   If /lang/pricing , where pricing isn't a valid lang will arrive, the expected
    #   retrued value will be {processed_path: "/lang/pricing", lang_tag: undefined}
    #
    # Note 1: that if lang_tag is undefined, you can expect prcessed_path to be the same as
    # req.originalUrl
    #
    # Note 2: the lang returned in lang_tag will be in the *correct* case for the lang tag (e.g. zh-tw > zh-TW)
    # and not the case received in the url. If the received lang from the url isn't matching the case correctly
    # we will also add, original_lang_tag to the returned object. (Not receiveing this means the lang tag was
    # correctly cased).

    original_url = req.originalUrl

    if not original_url.startsWith(JustdoI18n.langs_url_prefix)
      return {processed_path: original_url, lang_tag: undefined}

    # We got a lang prefixed original_url
    url_without_lang_prefix = original_url.substr JustdoI18n.langs_url_prefix.length
    url_segments = _.filter url_without_lang_prefix.split("/"), (url_segment) -> not _.isEmpty url_segment

    if _.isEmpty url_segments
      # This will happen if we got /lang only
      return {processed_path: original_url, lang_tag: undefined}

    original_lang_tag = url_segments.shift()
    # The following will return undefined, if unknown lang tag AND Normalize the case of the tag (e.g zh-tw > zh-TW)
    if not (lang_tag = @getLangTagIfSupported(original_lang_tag))?
      return {processed_path: original_url, lang_tag: undefined}

    processed_path = "/#{url_segments.join "/"}"

    if original_lang_tag isnt lang_tag
      return {processed_path, lang_tag, original_lang_tag}

    return {processed_path, lang_tag}
  
  getPathWithoutLangPrefix: (url) ->
    url_segments = _.filter url.split("/"), (url_segment) -> not _.isEmpty url_segment

    if _.isEmpty url_segments
      return "/"
    
    if url_segments.shift() isnt "lang"
      return url
    
    if not (lang_tag = url_segments.shift())?
      return
    
    return "/#{url_segments.join "/"}"
