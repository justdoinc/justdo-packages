_.extend JustdoI18nRoutes.prototype,
  _immediateInit: ->
    @_setupLangRedirectRules()
    @_setupPreloadLangsDetectors()
    @_setupHtmlAttrHook()

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
      #   3. Redirecting to the default language path if the language tag is not supported for the content

      processed_lang_details = @getStrippedPathAndLangFromReq(req)

      if not processed_lang_details.lang_tag?
        res.writeHead 404
        # XXX We should probably return a nicely-styled static 404 page here, like the one on Youtube
        res.end "404 Not Found"
        return

      if processed_lang_details.lang_tag is JustdoI18n.default_lang
        # We got a lang tag, but it's the default one, redirect to the path without the lang prefix
        res.writeHead 301,
          Location: processed_lang_details.processed_path
        res.end()
        return

      if processed_lang_details.original_lang_tag?
        # Getting original_lang_tag means the lang tag was not correctly cased, redirect to the correct case
        res.writeHead 301,
          Location: req.originalUrl.replace processed_lang_details.original_lang_tag, processed_lang_details.lang_tag
        res.end()
        return

      # Check if this path with this language is supported
      # This uses the same logic as in router.coffee's postMapGenerator
      hrp_path_without_lang = processed_lang_details.processed_path
      
      # Get supported languages for this path using our helper
      supported_langs = @getSupportedLangsForPath(hrp_path_without_lang)
      
      if not _.isEmpty(supported_langs) and (processed_lang_details.lang_tag not in supported_langs)
        # The content doesn't support this language - redirect to default lang
        res.writeHead 302, 
          Location: hrp_path_without_lang
        res.end()
        return

      # Case was fine, and it's not the default lang, continue
      next()

      return
    return

  _setupHtmlAttrHook: ->
    WebApp.addHtmlAttributeHook (req) =>
      # The req obj we receive here is different from the one in the connectHandlers, so we manually construct the param for getUrlLangFromReq.
      lang = @getUrlLangFromReq({originalUrl: req.path}) or JustdoI18n.default_lang
      return {lang}

    return

  _setupPreloadLangsDetectors: ->
    APP.justdo_i18n.registerLangsToPreloadDetector (req) => @getUrlLangFromReq req
    return

  getUrlLangFromReq: (req) -> @getStrippedPathAndLangFromReq(req).lang_tag
  getUrlLang: (absolute_path) -> @getUrlLangFromReq({originalUrl: absolute_path})

  # Server-only method to get the list of supported languages for a given path/route
  getSupportedLangsForPath: (path) ->
    # Remove HRP from path if possible
    path_without_hrp = if APP.justdo_seo?
      APP.justdo_seo.getPathWithoutHumanReadableParts(path)
    else
      path
    
    # Get route and check for language support restrictions
    route_name = JustdoHelpers.getRouteNameFromPath path_without_hrp
    route = Router.routes[route_name]
    
    # If the route isn't translatable, return only the default language
    if not route?.options?.translatable
      return [JustdoI18n.default_lang]
    
    all_supported_langs = _.keys APP.justdo_i18n.getSupportedLanguages()

    # Use the extracted function to get the i18n key
    i18n_key = @getI18nKeyToDetermineSupportedLangFromPath(path)
    
    # If no i18n key, return all supported languages
    if not i18n_key?
      return all_supported_langs
      
    # Get languages that have translations for this i18n key
    translated_langs = APP.justdo_i18n.getTranslatedLangsForI18nKey(i18n_key)
    # Ensure the returned languages are valid supported languages
    supported_langs = _.intersection translated_langs, all_supported_langs
    
    # If no translations found, return only default language
    if _.isEmpty(supported_langs)
      return [JustdoI18n.default_lang]
    
    return supported_langs
