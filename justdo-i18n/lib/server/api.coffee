_.extend JustdoI18n.prototype,
  _immediateInit: ->
    @_setupRedirectRules()
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

    return
  
  _setupRedirectRules: ->
    env = process.env

    if JustdoHelpers.getClientType(env) is "landing-app"
      WebApp.connectHandlers.use "/lang", (req, res, next) =>
        [url_lang, path] = _.filter req.url.split("/"), (url_segment) -> not _.isEmpty url_segment
        lang_tag = @getLangTagIfSupported url_lang
        path = path or ""
        path = "/#{path}"

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
      
    return

  _setupHandlebarsHelper: ->
    OriginalHandlebars.registerHelper "_", (key, args...) ->
      options = args.pop().hash
      if not _.isEmpty args
        options.sprintf = args
      
      return TAPi18n.__ key, options
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
