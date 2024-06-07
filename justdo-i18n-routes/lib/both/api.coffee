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

  getI18nPathDef: (path) -> 
    return @i18n_routes[path]

  isPathI18nAble: (path) -> 
    return @getI18nPathDef(path)?
  
  registerRoute: (route_path, routingFunction) ->
    if _.has @i18n_routes, route_path
      throw new @_error "not-supported", "Route #{route_path} is already registered."
    
    if not _.isFunction routingFunction
      throw new @_error "invalid-argument", "routingFunction must be a function."

    @i18n_routes[route_path] = {routingFunction}

    return