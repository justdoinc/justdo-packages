_.extend JustdoI18n.prototype,
  _immediateInit: ->
    @_setupDatepickerLocales()

    @lang_rv = new ReactiveVar amplify.store JustdoI18n.amplify_lang_key

    @force_rtl_routes = new Set()
    @force_rtl_routes_dep = new Tracker.Dependency()

    @tap_i18n_set_lang_tracker = Tracker.autorun =>
      lang = @getLang()

      TAPi18n.setLanguage lang
      i18n?.setLanguage lang
      jQuery.datepicker?.setDefaults jQuery.datepicker.regional[lang]
      bootbox.setLocale lang.replaceAll("-", "_")
      moment.locale lang.toLowerCase()
      return

    @_setupLandingPageTracker()

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

    Template.registerHelper "i18nCurrentPagePath", (lang) => @i18nCurrentPagePath lang

  _setupLandingPageTracker: ->
    if JustdoHelpers.getClientType(env) isnt "landing-app"
      return

    if not @set_lang_from_url_lang_tracker?
      @set_lang_from_url_lang_tracker = Tracker.autorun =>
        if (lang = @lang_rv.get())?
          return
        
        user_or_campaign_lang = @getUserLang() or APP.justdo_promoters_campaigns?.getCampaignDoc()?.lang
        if user_or_campaign_lang? and (user_or_campaign_lang isnt lang)
          @setLang user_or_campaign_lang, {skip_set_user_lang: true}

        return
    
    if not @set_url_lang_from_active_lang_tracker?
      @set_url_lang_from_active_lang_tracker = Tracker.autorun =>
        if not (router = Router.current())?
          return
          
        cur_path = router.route.path()
        if router.params?.path?
          cur_path = "/lang/#{router.params.path}"

        if (@isPathI18nAble cur_path) and (i18n_path = @i18nPath cur_path)?
          Router.go i18n_path

        return
      
    @onDestroy =>
      @set_lang_from_url_lang_tracker?.stop?()
      @set_url_lang_from_active_lang_tracker?.stop?()
      return
    
    return

  setLang: (lang, options) ->
    # options:
    #   save_to_local_storage: Boolean (optional) - Saves lang to local storage. Has no affect if current user is logged in.
    #   skip_set_user_lang: Boolean (optional) - Do not set user's lang. Only has effect if it's true.
    if Meteor.user()? and (options.skip_set_user_lang isnt true)
      @setUserLang lang
    else
      @lang_rv.set lang
      if options?.save_to_local_storage
        amplify.store JustdoI18n.amplify_lang_key, lang
    return
  
  getUrlLang: ->
    url_lang = Router.current()?.params?.lang or JustdoI18n.default_lang
    if (lang_tag = @getLangTagIfSupported url_lang)?
      return lang_tag

    return

  getLang: ->
    if (url_lang = @getUrlLang())? and url_lang isnt JustdoI18n.default_lang
      return url_lang

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
    @force_rtl_routes_dep.depend()
    if @force_rtl_routes.has route_name
      return false

    return @isLangRtl @getLang()

  forceLtrForRoute: (route_name, is_enable) ->
    if (not _.isString route_name) or _.isEmpty route_name
      @logger.error "forceLtrForRoute: route_name must be a non-empty string. Received #{route_name}"
      return

    old_force_rtl_routes = new Set @force_rtl_routes

    if (is_enable is true) or not is_enable?
      @force_rtl_routes.add route_name
    else
      @force_rtl_routes.delete route_name

    is_same_size_after_change = old_force_rtl_routes.size is @force_rtl_routes.size
    is_same_content_after_change = _.every old_force_rtl_routes.values(), (value) => @force_rtl_routes.has value

    if (not is_same_size_after_change) or (not is_same_content_after_change)
      @force_rtl_routes_dep.changed()
    
    return

  i18nPath: (path, lang) ->
    if not path?
      path = "/"

    if not lang?
      lang = APP.justdo_i18n.getLang()
    
    if not (lang = @getLangTagIfSupported lang)?
      return path

    if (lang is JustdoI18n.default_lang) or (not @isPathI18nAble path)
      return path or "/"

    return "/lang/#{lang}#{path or ""}"
    
  i18nCurrentPagePath: (lang) ->
    if not (router = Router.current())?
      return

    path = router.route.path()
    if router.params?.path?
      path = "/#{router.params.path}"
    
    return @i18nPath path, lang
