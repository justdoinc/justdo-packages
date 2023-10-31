_.extend JustdoI18n.prototype,
  _immediateInit: ->
    @_setupDatepickerLocales()

    @lang_rv = new ReactiveVar amplify.store JustdoI18n.amplify_lang_key

    @tap_i18n_set_lang_tracker = Tracker.autorun =>
      lang = @getLang()

      TAPi18n.setLanguage lang
      i18n?.setLanguage lang
      jQuery.datepicker?.setDefaults jQuery.datepicker.regional[lang]
      bootbox.setLocale lang.replaceAll("-", "_")
      moment.locale lang.toLowerCase()
      return

    @_setupBeforeUserSignUpHook()

    @_setupPlaceholderItems()
    @_registerGlobalTemplateHelpers()

    @onDestroy =>
      @tap_i18n_set_lang_tracker?.stop?()
      return

    return

  _deferredInit: ->
    if @destroyed
      return

    return
  
  _setupDatepickerLocales: ->
    if not jQuery.datepicker?
      @logger.info "_setupDatepickerLocales: jQuery.datepicker is undefined skipping"

      return
    
    supported_languages = _.without _.keys(@getSupportedLanguages()), "en"

    for lang in supported_languages
      if not (locale_conf = JustdoI18n.jquery_ui_datepicker_locale_confs[lang])?
        console.warn "Can't find jQuery UI Datepicker locale conf for language #{lang}"
        continue

      jQuery.datepicker.regional[lang] = locale_conf
    
    return

  _setupBeforeUserSignUpHook: ->
    APP.accounts.on "user-signup", (options) =>
      if (lang = @getLang())?
        options.profile.lang = lang
      return
      
    return

  _setupPlaceholderItems: ->
    APP.getEnv (env) ->
      if not (JustdoHelpers.getClientType(env) is "web-app")
        return

      if env.LANDING_PAGE_TYPE is "marketing" # IMPORTANT! if you remove this line, remove a similar condition in the landing app.
        APP.modules.main.user_config_ui.registerConfigSection "langs-selector",
          title: "Languages"
          priority: 50

        APP.modules.main.user_config_ui.registerConfigTemplate "langs-selector-dropdown",
          section: "langs-selector"
          template: "user_preference_lang_dropdown"
          priority: 100

      return

    return

  _registerGlobalTemplateHelpers: ->
    Template.registerHelper "getI18nTextOrFallback", (options) =>
      return @getI18nTextOrFallback options

  setLang: (lang, options) ->
    # options:
    #   save_to_local_storage: Boolean (optional) - Saves lang to local storage. Has no affect if current user is logged in.
    if Meteor.user()?
      @setUserLang lang
    else
      @lang_rv.set lang
      if options?.save_to_local_storage
        amplify.store JustdoI18n.amplify_lang_key, lang
    return
  
  getLang: ->
    if Meteor.user({fields: {"profile.lang": 1}})?
      return @getUserLang() or JustdoI18n.default_lang

    if (lang = @lang_rv.get())?
      return lang

    if (campaign_lang = APP.justdo_promoters_campaigns?.getCampaignDoc()?.lang)?
      return campaign_lang
        
    return JustdoI18n.default_lang
    
  generateI18nModalButtonLabel: (label) ->
    return JustdoHelpers.renderTemplateInNewNode("modal_button_label", {label}).node