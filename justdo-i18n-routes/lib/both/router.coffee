_.extend JustdoI18nRoutes.prototype,
  _langRouteHandler: (router_this) ->
    url_lang = router_this.params.lang
    path = router_this.params.path or ""
    path = "/#{path}"

    if not (lang_tag = @getLangTagIfSupported url_lang)?
      router_this.render "not_found"
      return
    
    if Meteor.isClient
      APP.justdo_i18n.setLang lang_tag, {skip_set_user_lang: true}

    if (route_def = @getI18nPathDef path)?
      route_def.routingFunction.call router_this
    else
      Router.go path

    return

  setupRouter: ->
    self = @

    Router.route "/lang/:lang", ->
      self._langRouteHandler @
      return
    , {name: "i18n_path_main_page"}

    Router.route "/lang/:lang/:path", ->
      self._langRouteHandler @
      return
    , {name: "i18n_path"}

    return