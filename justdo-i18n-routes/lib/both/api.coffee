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

  i18nPath: (path, lang) ->
    URL = JustdoHelpers.getURL()
  
    if not path?
      path = "/"
    
    # Ensure path is not a full url
    # E.g. Router.current().url would return the full url on the first few ticks.
    path = new URL(path, JustdoHelpers.getRootUrl()).pathname

    if not lang?
      if Meteor.isClient
        lang = APP.justdo_i18n.getLang()
      if Meteor.isServer
        throw @_error "missing-argument", "i18nPath: lang is required."
    
    if not (lang = @getLangTagIfSupported lang)?
      return path
    
    route_name = JustdoHelpers.getRouteNameFromPath path
    if not (route_def = @getI18nRouteDef route_name)?
      return path or "/"
    
    # If the route options has custom i18nPath specified, 
    # we'll use the returned value of it instead of simply adding "/lang/[lang]" to the url
    if _.isFunction route_def.route_options.i18nPath
      original_path = path
      
      # On the server simply return the value
      if Meteor.isServer
        path = route_def.route_options.i18nPath original_path, lang
      # On the client, we call "getI18nPathFromRouteOptions" method to obtain the value we get from the server side (the line above)
      # We also store the value to @i18n_paths_cache and trigger @i18n_paths_cache_dep.changed()
      # so subsequent calls to this method with the same params will not trigger another method call.
      if Meteor.isClient
        @i18n_paths_cache_dep.depend()

        if (cached_path = @i18n_paths_cache[original_path]?[lang])?
          # If cached_path is "pending", it means that there's already an ongoing method call for the same params.
          # In that case we'll first return the path after simply adding "/lang/[lang]".
          # Upon receiving the value from the method, @i18n_paths_cache_dep.changed() will trigger rerun and return the value from i18n_paths_cache.
          if cached_path isnt "pending"
            return cached_path
        else
          if not @i18n_paths_cache[original_path]?
            @i18n_paths_cache[original_path] = {}
          # Set the value to pending to avoid double-calling the method with the same params.
          @i18n_paths_cache[original_path][lang] = "pending"
          @getI18nPathFromRouteOptions path, lang, (err, i18n_path) =>
            if err?
              console.error err
              return
            
            @i18n_paths_cache[original_path][lang] = i18n_path
            @i18n_paths_cache_dep.changed()

            return
    
    if lang is JustdoI18n.default_lang
      return path or "/"

    return "#{JustdoI18nRoutes.langs_url_prefix}/#{lang}#{if path is "/" then "" else path}"

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

    if not original_url.startsWith(JustdoI18nRoutes.langs_url_prefix)
      return {processed_path: original_url, lang_tag: undefined}

    # We got a lang prefixed original_url
    url_obj = new URL original_url, JustdoHelpers.getRootUrl()
    url_without_lang_prefix = url_obj.pathname.substr JustdoI18nRoutes.langs_url_prefix.length
    url_segments = _.filter url_without_lang_prefix.split("/"), (url_segment) -> not _.isEmpty url_segment

    if _.isEmpty url_segments
      # This will happen if we got /lang only
      return {processed_path: original_url, lang_tag: undefined}

    original_lang_tag = url_segments.shift()
    # The following will return undefined, if unknown lang tag AND Normalize the case of the tag (e.g zh-tw > zh-TW)
    if not (lang_tag = @getLangTagIfSupported(original_lang_tag))?
      return {processed_path: original_url, lang_tag: undefined}

    lang_prefix_regex = new RegExp "^#{JustdoI18nRoutes.langs_url_prefix}/\w+"
    processed_path = "/#{url_segments.join "/"}".replace lang_prefix_regex, ""

    if original_lang_tag isnt lang_tag
      return {processed_path, lang_tag, original_lang_tag}

    return {processed_path, lang_tag}
  
  getPathWithoutLangPrefix: (url) -> @getStrippedPathAndLangFromReq({originalUrl: url}).processed_path
  