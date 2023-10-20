_.extend JustdoI18n.prototype,
  _bothImmediateInit: ->
    # @_bothImmediateInit runs before the specific env's @_immediateInit()

    # Add here code that should run, in the Server and Client, during the JS
    # tick in which we create the object instance.

    @setupRouter()
    @_setupMomentLocales()

    return

  _bothDeferredInit: ->
    # @_bothDeferredInit runs before the specific env's @_deferredInit()

    # Add here code that should run, in the Server and Client, after the JS
    # tick in which we created the object instance.

    if @destroyed
      return

    return
  
  _setupMomentLocales: ->
    supported_languages = _.without _.keys(@getSupportedLanguages()), "en"

    for lang in supported_languages
      lang = lang.toLowerCase()
      if not (locale_conf = JustdoI18n.moment_locale_confs[lang])?
        console.warn "Can't find Moment.js locale conf for language #{lang}"
        continue

      moment.defineLocale lang, locale_conf

    return

  getUserLang: (user) ->
    # For non logged-in users, we'll return undefined.
    # In most cases, you should use getLang() on client side.
    if Meteor.isClient
      if not user?
        user = Meteor.user({fields: {"profile.lang": 1}})
    else
      if _.isString user
        user = Meteor.users.findOne(user, {fields: {"profile.lang": 1}})
    
    return user?.profile?.lang
  
  setUserLang: (lang, user_id) ->
    # This api only updates lang in user_doc without updating local storage
    # In most cases, you should use setLang() on client side.
    check lang, Match.Maybe String

    if Meteor.isClient
      user_id = Meteor.userId()
    else
      if not user_id?
        throw @_error "missing-argument"
    
    if @getUserLang(user_id) is lang
      @logger.info "setUserLang: #{lang} is already the user's lang"
      return

    update = 
      $set:
        "profile.lang": lang

    Meteor.users.update user_id, update

    return

  getSupportedLanguages: ->
    return TAPi18n.getLanguages()
  
  getI18nTextOrFallback: (options) ->
    # Object params passed from template helper will be encapsulated inside hash
    if options.hash?
      options = options.hash

    {fallback_text, i18n_key, i18n_options, lang} = options

    if not i18n_key?
      return fallback_text

    check fallback_text, String
    check i18n_key, String
    if Meteor.isServer
      # lang is required in server only
      check lang, String
    
    if (translated_text = TAPi18n.__ i18n_key, i18n_options, lang) isnt i18n_key
      return translated_text

    return fallback_text

  # For use in cases like the states field, where the label could be customised.
  # If provided "text" isn't the same as translated text under default_lang, provided "text" will be returned.
  # Else return translated version.
  getDefaultI18nTextOrCustomInput: (options) ->
    {text, i18n_key, i18n_options, lang} = options
    check text, String
    
    i18n_options = {i18n_key, i18n_options, lang: JustdoI18n.default_lang, fallback_text: text}
    i18n_text = @getI18nTextOrFallback i18n_options

    if text isnt i18n_text
      return text
    
    delete i18n_options.lang
    return @getI18nTextOrFallback i18n_options
