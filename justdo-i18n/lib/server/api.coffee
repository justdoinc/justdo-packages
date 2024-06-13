_.extend JustdoI18n.prototype,
  _immediateInit: ->
    @langs_to_preload_predicates = []
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

    @_setupHandlebarsHelper()

    @_setupConnectHandlers()

    return
  
  _setupHandlebarsHelper: ->
    OriginalHandlebars.registerHelper "_", (key, args...) ->
      options = args.pop().hash
      if not _.isEmpty args
        options.sprintf = args
      
      return TAPi18n.__ key, options
    return

  _setupConnectHandlers: ->
    WebApp.connectHandlers.use "/", (req, res, next) =>
      # Do not send the title and description for non-registered routes (e.g. /tap-i18n/all.json)
      if not (route_name = JustdoHelpers.getRouteNameFromPath req.url)?
        next()
        return

      langs_to_preload = @getLangsToPreload req
      if (user_lang = @getUserLangFromMeteorLoginTokenCookie req)?
        langs_to_preload.push user_lang
      
      langs_to_preload = _.uniq langs_to_preload
      console.log langs_to_preload

      next()

      return

  tr: (key, options, user) ->
    # If user isn't provided, we use Meteor.user().
    #
    # There are situations (outside methods/pubs) where Meteor.user() isn't available,
    # in those cases, you'll have to pass user, otherwise we will use the fallback language.
    #
    # If user is provided, it must be either:
    #
    #   1. An object with "profile.lang"
    #   2. A user id

    try
      if not user?
        user = Meteor.user({fields: {"profile.lang": 1}})
    catch e
      console.warn "JustdoI18n.__ called invoked outside of a method call or a publication, falling back to no-user."
      user = undefined

    lang_tag = @getUserLang(user) or JustdoI18n.default_lang

    options = _.extend {}, options
    return TAPi18n.__(key, options, lang_tag)

  defaultTr: (key, options) ->
    # Forcing translation of key to JustdoI18n.default_lang even if we have
    # Meteor.user() available
    return @tr(key, options, {profile: {lang: JustdoI18n.default_lang}})

  getUserLangFromMeteorLoginTokenCookie: (req) ->
    return JustdoHelpers.getUserObjFromMeteorLoginTokenCookie(req, {fields: {"profile.lang": 1}})?.profile?.lang
  
  registerLangsToPreloadPredicate: (predicate) ->
    @langs_to_preload_predicates.push predicate
    return
  
  getLangsToPreload: (req) ->
    langs_to_preload = []

    for predicate in @langs_to_preload_predicates
      langs = predicate req
      if not _.isEmpty langs
        if _.isString langs
          langs_to_preload.push langs
        if _.isArray langs
          langs_to_preload = langs_to_preload.concat langs
    
    return langs_to_preload