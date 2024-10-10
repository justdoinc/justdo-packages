_.extend JustdoI18nRoutes.prototype,
  _immediateInit: ->
    @_registerGlobalTemplateHelpers()
    @_setupLangUrlTracker()

    return

  _deferredInit: ->
    if @destroyed
      return

    return

  _registerGlobalTemplateHelpers: ->
    Template.registerHelper "i18nCurrentPagePath", (lang) => @i18nCurrentPagePath lang
    Template.registerHelper "i18nRoute", (options) => 
      path = Blaze._globalHelpers.pathFor options
      return @i18nPath(path) or path

    return

  _setupLangUrlTracker: ->
    if not @set_url_lang_from_active_lang_tracker?
      # This tracker redirects user back to the page with the correct lang prefix
      # e.g. If user entered "/pricing", and the active lang is not default lang due to user_doc or campaign, 
      # it will redirect to "#{JustdoI18nRoutes.langs_url_prefix}/active_lang/pricing" so that lang router can handle it.
      @set_url_lang_from_active_lang_tracker = Tracker.autorun =>
        if not (router = Router.current())?
          return
        
        # If lang is already specified in the url, do nothing (the lang router will handle calling setLang based on the url lang).
        if @getUrlLang()?
          return
          
        cur_path = @getCurrentPathWithoutLangPrefix()
        cur_route_name = @getCurrentRouteName()

        if (@isRouteI18nAble cur_route_name) and (i18n_path = @i18nPath cur_path)?
          Router.go i18n_path

        return
      
    @onDestroy =>
      @set_url_lang_from_active_lang_tracker?.stop?()
      return
    
    return

  # Note: This method will never return JustdoI18n.default_lang,
  # because when #{JustdoI18nRoutes.langs_url_prefix}/#{JustdoI18n.default_lang} is accessed, it will redirect to /
  getUrlLang: ->
    if not (url_lang = Router.current()?.params?.lang)?
      return
      
    return url_lang
    
  i18nCurrentPagePath: (lang) ->
    if not (router = Router.current())?
      return

    path = @getCurrentPathWithoutLangPrefix()
    
    return @i18nPath path, lang

  getCurrentPathWithoutLangPrefix: ->
    if not (router = Router.current())?
      return
    
    if not (cur_route_name = router.route?.getName())?
      return
      
    cur_route_params = router.getParams()
    # If current route is not i18n_path, generate path using route name and params
    if cur_route_name.startsWith "i18n_path"
      cur_route_name = JustdoHelpers.getRouteNameFromPath cur_route_params.path

    path = Router.path cur_route_name, cur_route_params, {query: cur_route_params.query, hash: cur_route_params.hash}

    return path

  getCurrentRouteName: ->
    if not (router = Router.current())?
      return
    
    if not (cur_route_name = router.route?.getName())?
      return
    
    if not cur_route_name.startsWith "i18n_path"
      return cur_route_name
    
    cur_path_without_lang_prefix = "/#{router.getParams().path or ""}"

    return JustdoHelpers.getRouteNameFromPath cur_path_without_lang_prefix