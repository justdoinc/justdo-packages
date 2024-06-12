_.extend JustdoI18n.prototype,
  _immediateInit: ->
    @_setupDatepickerLocales()
    
    @get_lang_registry = {}
    JustdoHelpers.setupPlaceholdersReactiveListRegistry @get_lang_registry

    @lang_rv = new ReactiveVar amplify.store JustdoI18n.amplify_lang_key

    @force_ltr_routes = new Set()
    @force_ltr_routes_dep = new Tracker.Dependency()


    @tap_i18n_set_lang_tracker = Tracker.autorun =>
      lang = @getLang()

      TAPi18n.setLanguage lang
      i18n?.setLanguage lang

      # On the initial load, bootbox might not be loaded yet, try to set it again after app accounts are ready
      # (which is quite late in the init process)
      # The hooks will be called in the order they were added, so don't worry
      # about later changes to lang being overriden by prior calls where lang
      # isn't determined yet
      APP.executeAfterAppAccountsReady =>
        bootbox.setLocale lang.replaceAll("-", "_")
        return
    
      jQuery.datepicker?.setDefaults jQuery.datepicker.regional[lang]
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
    #   save_to_local_storage: Boolean (optional) - Saves lang to local storage. Has no affect if current user is logged in.
    #   skip_set_user_lang: Boolean (optional) - Do not set user's lang. Only has effect if it's true.
    if Meteor.user()? and (options?.skip_set_user_lang isnt true)
      @setUserLang lang
    else
      @lang_rv.set lang
      if options?.save_to_local_storage
        amplify.store JustdoI18n.amplify_lang_key, lang
    return

  getLang: ->
    for item in @get_lang_registry.getPlaceholderItems "getLangHighPriority"
      if (handler_lang = item.handler?())?
        return handler_lang

    if (lang = @lang_rv.get())?
      return lang

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
  
  # Handlers registered via this method will be used in getLang,
  # and the first handler that returns a non-empty value will be used.
  # The handlers will be processed first before any other lang checking logics (see getLang for details)
  registerHighPriorityGetLangHandler: (item_id, handler) ->
    if not _.isFunction handler
      throw @_error "invalid-argument", "handler must be a function"
    @get_lang_registry.registerPlaceholderItem item_id,
      domain: "getLangHighPriority"
      data:
        handler: handler

    return