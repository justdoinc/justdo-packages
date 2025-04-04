_.extend JustdoI18nRoutes.prototype,
  _bothImmediateInit: ->
    # @_bothImmediateInit runs before the specific env's @_immediateInit()

    # Add here code that should run, in the Server and Client, during the JS
    # tick in which we create the object instance.

    @i18n_routes = {}

    @setupRouter()

    return

  _bothDeferredInit: ->
    # @_bothDeferredInit runs before the specific env's @_deferredInit()

    # Add here code that should run, in the Server and Client, after the JS
    # tick in which we created the object instance.

    if @destroyed
      return

    return

  # If lang_tag is supported, return it in the correct case (e.g. zh-tw > zh-TW).
  # Else return undefined.
  getLangTagIfSupported: (lang_tag) ->
    lower_case_lang_tag = lang_tag.toLowerCase()
    supported_languages = _.keys APP.justdo_i18n.getSupportedLanguages()
    return _.find supported_languages, (supported_lang_tag) -> supported_lang_tag.toLowerCase() is lower_case_lang_tag

  getI18nRouteDef: (route_name) -> 
    return @i18n_routes[route_name]

  isRouteI18nAble: (route_name) -> 
    return @getI18nRouteDef(route_name)?
  
  _registerRoutesItemSchema: new SimpleSchema
    path: 
      type: String
    routingFunction:
      type: Function
    route_options:
      type: Object
      blackbox: true
  registerRoutes: (routes) ->
    if not _.isArray routes
      routes = [routes]

    cleaned_routes = []

    for route in routes
      {cleaned_val} = JustdoHelpers.simpleSchemaCleanAndValidate(
        @_registerRoutesItemSchema,
        route,
        {self: @, throw_on_error: true}
      )
      route = cleaned_val
      cleaned_routes.push route
    
      if not (route_name = route.route_options.name)?
        throw @_error "missing-argument": "registerRoutes: route_options.route_name is required."
      
      if _.has @i18n_routes, route_name
        throw @_error "not-supported", "registerRoutes: Route #{route_name} is already registered."
    
    for route in cleaned_routes
      do (route) =>
        route_name = route.route_options.name
        
        # Register regular route
        Router.route route.path, -> 
          route.routingFunction.call @
          return
        , route.route_options or {}

        # Mark route is i18n-ready so #{JustdoI18nRoutes.langs_url_prefix}/:lang will work
        @i18n_routes[route_name] = {routingFunction: route.routingFunction, route_options: route.route_options}

        return

    return

  i18nPath: (path, lang, options = {}) ->
    # This function is used to convert a path to an i18n path.
    #
    # Arguments:
    #
    #   path: can be either a full url (incl. domain + protocol) or just the absolute
    #   url path.
    #
    #   lang: is required in the server, but optional in the client.
    #         note that if lang isn't provided, we will use the current lang in the client.
    #         this will make this function a reactive resource.
    #
    #   options:
    #     skip_lang_check: if true, we will not check if the lang is supported for this path.

    if not path?
      path = "/"

    # Ensure to take only the absolute path from path in case that it got provided with the full url
    #
    # We support full url, because we noticed that in the first load, Iron Router
    # might return the full url, instead of its usual absolute url path.
    path = JustdoHelpers.getNormalisedUrlPathname(path)
  
    if not lang?
      if Meteor.isClient
        lang = APP.justdo_i18n.getLang()
      if Meteor.isServer
        throw @_error "missing-argument", "i18nPath: lang is required."
    
    if not (lang = @getLangTagIfSupported lang)?
      return path
    
    route_name = JustdoHelpers.getRouteNameFromPath path
    
    # If it's the default language or the route is not i18n-able, return the path as is
    if (lang is JustdoI18n.default_lang) or (not @isRouteI18nAble route_name)
      return path
    
    # Server-side language support check
    if options.skip_lang_check
      if Meteor.isClient
        throw @_error "not-supported", "i18nPath: skip_lang_check option is not supported in the client."
    else if Meteor.isServer
      # Check if this language is supported for this path
      supported_langs = @getSupportedLangsForPath(path)
      # If the current language is not supported, return path without language prefix
      if not _.isEmpty(supported_langs) and lang not in supported_langs
        return path
    
    return "#{JustdoI18nRoutes.langs_url_prefix}/#{lang}#{if path is "/" then "" else path}"

  i18nPathAndHrp: (path, lang) ->
    # The HRP concept is introduced by the justdo_seo package, yet, we found it more
    # convenient to have a single function that will return both the i18n path and the
    # human readable path - and place it here, at least for now.
    #
    # This function is used to convert a path to an i18n path and a human readable path.
    #
    # In environments where JustdoSeo isn't available, this function will return the same
    # value as @i18nPath().
    #
    # Note that in the client side this is a reactive resource.

    if not path?
      path = "/"
    
    # First get the i18n path (which now checks for language support)
    path = @i18nPath path, lang

    # Then apply HRP if available
    if APP.justdo_seo?
      return APP.justdo_seo.getCanonicalHrpURL(path)

    return path

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
    #
    # Note 3: We only use the originalUrl of the req object. As such, you can
    # mimic the behavior of this function by passing an object with an originalUrl.

    URL = JustdoHelpers.getURL()
    original_url = req.originalUrl
    path = JustdoHelpers.getNormalisedUrlPathname(original_url)

    if not path.startsWith(JustdoI18nRoutes.langs_url_prefix)
      return {processed_path: original_url, lang_tag: undefined}

    # We got a lang prefixed original_url
    url_without_lang_prefix = path.substr JustdoI18nRoutes.langs_url_prefix.length
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
  
  getStrippedPathAndLang: (url) -> @getStrippedPathAndLangFromReq({originalUrl: url})

  getPathWithoutLangPrefix: (url) -> @getStrippedPathAndLang(url).processed_path
  
  # Get the i18n key that determines which languages are supported for a given path
  getI18nKeyToDetermineSupportedLangFromPath: (path) ->
    # Remove HRP from path if possible
    path_without_hrp = if APP.justdo_seo?
      APP.justdo_seo.getPathWithoutHumanReadableParts(path)
    else
      path
    
    # Get route and check for language support restrictions
    route_name = JustdoHelpers.getRouteNameFromPath path_without_hrp
    route = Router.routes[route_name]
    
    # If the route isn't translatable or doesn't have the function, return undefined
    if not route?.options?.translatable or not route?.options?.getI18nKeyToDetermineSupportedLangs?
      return undefined
    
    # Return the i18n key that determines supported languages for this path
    return route.options.getI18nKeyToDetermineSupportedLangs(path_without_hrp)
  