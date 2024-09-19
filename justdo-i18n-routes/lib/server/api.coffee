_.extend JustdoI18nRoutes.prototype,
  _immediateInit: ->
    @post_map_generators = {}

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

      processed_lang_details = @getStrippedPathAndLangFromReq(req)

      if not processed_lang_details.lang_tag?
        res.writeHead 404
        # XXX We should probably return a nicely-styled static 404 page here, like the one on Youtube
        res.end "404 Not Found"
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

  # This method allows other plugins to register a post map generator that will be called inside the postMapGenerator
  # of i18n route (see router.coffee). 
  # An example use case would be the url of justdo-news, where we'll have translated text in the url depending on the lang.
  _registerPostMapGeneratorOptionsSchema: new SimpleSchema
    predicate:
      type: Function
    generator:
      type: Function
  registerPostMapGenerator: (id, options) ->
    check id, String

    {cleaned_val} = JustdoHelpers.simpleSchemaCleanAndValidate(
      @_registerPostMapGeneratorOptionsSchema,
      options,
      {self: @, throw_on_error: true}
    )
    options = cleaned_val
    
    @post_map_generators[id] = options

    return
  
  getPostmapGenerators: -> @post_map_generators