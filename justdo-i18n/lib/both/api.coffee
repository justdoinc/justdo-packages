_.extend JustdoI18n.prototype,
  _bothImmediateInit: ->
    # @_bothImmediateInit runs before the specific env's @_immediateInit()

    # Add here code that should run, in the Server and Client, during the JS
    # tick in which we create the object instance.

    @disable_rtl_support_rv = new ReactiveVar false
  
    @_setupI18nextPluralRule()
    @_replaceDefaultLanguageNames()
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
  
  _setupI18nextPluralRule: ->
    # For some reason Chinese doesn't have built-in plural form. Here we add it back using the same rules as English.
    en_plural_form = TAPi18next.pluralExtensions.rules.en
    TAPi18next.pluralExtensions.addRule("zh", {name: "Chinese", numbers: en_plural_form.numbers, plurals: en_plural_form.plurals})
    return

  _replaceDefaultLanguageNames: ->
    TAPi18n.languages_names["zh-TW"] = ["Chinese (Traditional)", "繁體中文"]
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
  
  # If lang_tag is supported, return it in the correct case (e.g. zh-tw > zh-TW).
  # Else return undefined.
  getLangTagIfSupported: (lang_tag) ->
    lower_case_lang_tag = lang_tag.toLowerCase()
    supported_languages = _.keys @getSupportedLanguages()
    return _.find supported_languages, (supported_lang_tag) -> supported_lang_tag.toLowerCase() is lower_case_lang_tag
  
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

  isLangRtl: (lang) ->
    if @disable_rtl_support_rv.get()
      return false

    return lang in JustdoI18n.supported_rtl_langs

  getI18nPathDef: (path) -> 
    return APP.landing_page?.route_definition_by_path?[path]

  isPathI18nAble: (path) -> 
    return @getI18nPathDef(path)?

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