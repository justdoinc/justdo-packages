_.extend JustdoI18n.prototype,
  _immediateInit: ->
    @forced_runtime_lang_rv = new ReactiveVar amplify.store JustdoI18n.amplify_lang_key

    @force_ltr_routes = new Set()
    @force_ltr_routes_dep = new Tracker.Dependency()

    # XXX The APP.executeAfterAppClientCode wrap is necessary because on the first page load,
    # XXX TAPi18n's list of supported languages may not be fully initialized as specified in project-tap.i18n.
    # XXX Therefore we wrap the tracker with APP.executeAfterAppClientCode to give extra time for TAPi18n to be fully initialized.
    # XXX Once that issue is resolved, we can remove the APP.executeAfterAppClientCode wrap.
    APP.executeAfterAppClientCode =>
      @tap_i18n_set_lang_tracker = Tracker.autorun =>
        lang = @getLang()
        
        TAPi18n.setLanguage lang
        i18n?.setLanguage lang

        # On the initial load, bootbox might not be loaded yet, try to set it again after app accounts are ready
        # (which is quite late in the init process)
        # The hooks will be called in the order they were added, so don't worry
        # about later changes to lang being overriden by prior calls where lang
        # isn't determined yet
        
        # Bootbox will fallback to en if the language is not supported
        bootbox.setLocale lang.replaceAll("-", "_")

        # Datepicker doesn't have a fallback mechanism, so we need to check if the language is supported
        # and use the default language if it's not
        if (datepicker = jQuery.datepicker)?
          locale_config = jQuery.datepicker.regional[lang] or jQuery.datepicker.regional[JustdoI18n.default_lang]
          datepicker.setDefaults locale_config

        # Moment.js doesn't have a fallback mechanism, so we need to check if the language is supported
        # and use the default language if it's not
        moment_lang = lang.toLowerCase()
        if moment_lang in moment.locales()
          moment.locale moment_lang
        else
          moment.locale JustdoI18n.default_lang

        $("html").attr "lang", lang
        return
      
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

  _setupBeforeUserSignUpHook: ->
    APP.once "app-accounts-ready", =>
      APP.accounts.on "user-signup", (options) =>
        if (lang = @getLang())?
          options.profile.lang = lang
        return
      return
    return

  _setupPlaceholderItems: ->
    APP.getEnv (env) ->
      if not (JustdoHelpers.getClientType(env) is "web-app")
        return

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
    
    Template.registerHelper "isRtl", (route_name) => @isRtl route_name

  setLang: (lang, options) ->
    # options:
    #   skip_set_user_lang: Boolean (optional) - Do not set user's lang. Only has effect if it's true.

    @setForcedRuntimeLang(lang)

    if Meteor.user()? and (options?.skip_set_user_lang isnt true)
      @setUserLang lang
    else
      amplify.store JustdoI18n.amplify_lang_key, lang
    return

  setForcedRuntimeLang: (lang) ->
    @forced_runtime_lang_rv.set lang

    return

  clearForcedRuntimeLang: ->
    @forced_runtime_lang_rv.set null

    return

  _getForcedRuntimeLang: ->
    return @forced_runtime_lang_rv.get()

  getLang: ->
    if (runtime_lang = @_getForcedRuntimeLang())?
      return runtime_lang

    if Meteor.user({fields: {"profile.lang": 1}})?
      return @getUserLang() or JustdoI18n.default_lang

    if (campaign_lang = APP.justdo_promoters_campaigns?.getCampaignDoc()?.lang)?
      return campaign_lang
        
    return JustdoI18n.default_lang
    
  generateI18nModalButtonLabel: (label) ->
    return JustdoHelpers.renderTemplateInNewNode("modal_button_label", {label}).node
  
  getVimeoLangTag: (lang_tag) ->
    if not lang_tag?
      lang_tag = @getLang()

    if (vimeo_lang_tag = JustdoI18n.vimeo_lang_tags[lang_tag])?
      return vimeo_lang_tag
      
    return lang_tag
  
  isRtl: (route_name) ->
    @force_ltr_routes_dep.depend()
    if @force_ltr_routes.has route_name
      return false

    return @isLangRtl @getLang()
