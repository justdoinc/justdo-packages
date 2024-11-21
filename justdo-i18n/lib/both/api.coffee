_.extend JustdoI18n.prototype,
  _bothImmediateInit: ->
    # @_bothImmediateInit runs before the specific env's @_immediateInit()

    # Add here code that should run, in the Server and Client, during the JS
    # tick in which we create the object instance.

    @disable_rtl_support_rv = new ReactiveVar false
  
    @_setupI18nextPluralRule()
    APP.executeAfterAppLibCode =>
      # If called before the app is ready, TAPi18n may not be fully initialized yet and our custom language names will be overrided.
      @_replaceDefaultLanguageNames()
    @setupRouter()
    @_loadEnvSupportedLanguages()

    return

  _bothDeferredInit: ->
    # @_bothDeferredInit runs before the specific env's @_deferredInit()

    # Add here code that should run, in the Server and Client, after the JS
    # tick in which we created the object instance.

    if @destroyed
      return

    return
  
  _loadEnvSupportedLanguages: ->
    @env_supported_languages = 
      default: [JustdoI18n.default_lang]
    if Meteor.isClient
      @env_supported_languages_dep = new Tracker.Dependency()

    # Load supported languages from env
    APP.getEnv (env) =>
      for type in _.without(JustdoI18n.supported_language_group_types, "default")
        @env_supported_languages[type] = env["I18N_#{type.toUpperCase()}_SUPPORTED_LANGUAGES"].replace(/\s/g, "").split ","
      
      if Meteor.isClient
        @env_supported_languages_dep.changed()

      return

    return
  
  # NOTE: This method is meant for internal use only,
  # because it doesn't take into account TAPi18n's supported languages.
  # Use getSupportedLanguages instead.
  _getEnvSupportedLanguages: (type) ->
    if Meteor.isClient
      @env_supported_languages_dep.depend()

    if not type?
      return @env_supported_languages

    if type not in JustdoI18n.supported_language_group_types
      throw @_error "invalid-argument", "_getEnvSupportedLanguages: type must be one of #{JustdoI18n.supported_language_group_types.join(", ")}. Received #{type}"

    return @env_supported_languages[type]

  _setupI18nextPluralRule: ->
    # For some reason Chinese doesn't have built-in plural form. Here we add it back using the same rules as English.
    en_plural_form = TAPi18next.pluralExtensions.rules.en
    TAPi18next.pluralExtensions.addRule("zh", {name: "Chinese", numbers: en_plural_form.numbers, plurals: en_plural_form.plurals})
    return

  _replaceDefaultLanguageNames: ->
    TAPi18n.languages_names["zh-TW"] = ["Chinese (Traditional)", "繁體中文"]
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

  getSupportedLanguages: (lang_group_type="all", return_lang_tag_only=false) ->
    # Note: TAPi18n.getLanguages() returns an object
    tapi18n_langs = TAPi18n.getLanguages()

    lang_tags_under_group = @_getEnvSupportedLanguages lang_group_type
    lang_group = _.pick tapi18n_langs, ...lang_tags_under_group

    if return_lang_tag_only
      lang_group = _.keys lang_group
    
    return lang_group
  
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
    
    i18n_options.lang = lang
    return @getI18nTextOrFallback i18n_options

  forceLtrForRoute: (route_name) ->
    if Meteor.isServer
      return
      
    if (not _.isString route_name) or _.isEmpty route_name
      @logger.error "forceLtrForRoute: route_name must be a non-empty string. Received #{route_name}"
      return
    
    if @force_ltr_routes.has route_name
      return

    @force_ltr_routes.add route_name

    @force_ltr_routes_dep.changed()
    
    return

  isLangRtl: (lang) ->
    if @disable_rtl_support_rv.get()
      return false

    return lang in JustdoI18n.supported_rtl_langs

  disableRtlSupport: ->
    # When the app doesn't support RTL properly, it is likely that you would want to disable
    # cases where we modify the UI for RTL languages.
    #
    # An example for this are dialogs that are positioned differently for RTL languages.
    # The bootbox package adds the rtl and right-to-left classes when it detects based
    # on justdo-i18n that the current language is rtl. But, if the dialog weren't prepared
    # to be in RTL, it might look bad.
    #
    # For situations like this, you can call this method early on in your app's lifecycle.
    #
    # This will ensure that even if the language is RTL, RTL-specific modifications won't be made
    # to the DOM by justdo-i18n and other packages that depend on it.

    @disable_rtl_support_rv.set true
    
    return
  
  isRouteTranslatable: (route_name) ->
    route = Router.routes[route_name]
    return route?.options?.translatable