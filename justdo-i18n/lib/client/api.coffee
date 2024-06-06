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
        
        # If lang is already specified in the url, do nothing.
        if @getUrlLang()?
          return
          
        cur_path = @getOriginalCurrentPath()

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
    if Meteor.user()? and (options?.skip_set_user_lang isnt true)
      @setUserLang lang
    else
      @lang_rv.set lang
      if options?.save_to_local_storage
        amplify.store JustdoI18n.amplify_lang_key, lang
    return
  
  # Note: This method will never return JustdoI18n.default_lang,
  # because when /lang/#{JustdoI18n.default_lang} is accessed, it will redirect to /
  getUrlLang: ->
    if not (url_lang = Router.current()?.params?.lang)?
      return
      
    return url_lang

  getLang: ->
    if (url_lang = @getUrlLang())?
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

  i18nPath: (path, lang) ->
    if not path?
      path = "/"

    if not lang?
      lang = APP.justdo_i18n.getLang()
    
    if not (lang = @getLangTagIfSupported lang)?
      return path

    if (lang is JustdoI18n.default_lang) or (not @isPathI18nAble path)
      return path or "/"

    return "/lang/#{lang}#{if path is "/" then "" else path}"
    
  i18nCurrentPagePath: (lang) ->
    if not (router = Router.current())?
      return

    path = @getOriginalCurrentPath()
    
    return @i18nPath path, lang

  getOriginalCurrentPath: ->
    if not (router = Router.current())?
      return
    
    if not (cur_route_name = router.route?.getName())?
      return
      
    # If current route is not i18n_path, generate path using route name and params
    if cur_route_name.startsWith "i18n_path"
      if cur_route_name is "i18n_path_main_page"
        return "/"
      
      return "/#{router.getParams().path}"

    cur_route_name = router.route?.getName()
    cur_route_params = router.getParams()
    path = Router.path cur_route_name, cur_route_params

    return path