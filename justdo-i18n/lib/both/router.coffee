_.extend JustdoI18n.prototype,
  _langRouteHandler: (router_this) ->
    url_lang = router_this.params.lang
    path = router_this.params.path or ""
    path = "/#{path}"

    if not (lang_tag = @getLangTagIfSupported url_lang)?
      router_this.render "not_found"
      return

    if (route_def = @getI18nPathDef path)?
      route_def.action.call router_this
    else
      Router.go path

    return

  setupRouter: ->
    self = @
    env = process.env or env

    if JustdoHelpers.getClientType(env) is "landing-app"
      Router.route "/lang/:lang", ->
        self._langRouteHandler @
        return

      Router.route "/lang/:lang/:path", ->
        self._langRouteHandler @
        return

    return