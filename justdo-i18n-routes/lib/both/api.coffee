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
    if not path?
      path = "/"

    if not lang?
      if Meteor.isClient
        lang = APP.justdo_i18n.getLang()
      if Meteor.isServer
        throw @_error "missing-argument", "i18nPath: lang is required."
    
    if not (lang = @getLangTagIfSupported lang)?
      return path
    
    route_name = JustdoHelpers.getRouteNameFromPath path
    if (lang is JustdoI18n.default_lang) or (not @isRouteI18nAble route_name)
      return path or "/"

    return "#{JustdoI18nRoutes.langs_url_prefix}/#{lang}#{if path is "/" then "" else path}"
