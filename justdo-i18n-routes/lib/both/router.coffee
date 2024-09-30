_.extend JustdoI18nRoutes.prototype,
  _langRouteHandler: (router_this) ->
    url_lang = router_this.params.lang
    path = router_this.params.path or ""
    path = "/#{path}"
    route_name = JustdoHelpers.getRouteNameFromPath path

    if not (lang_tag = @getLangTagIfSupported url_lang)?
      router_this.render "not_found"
      return
    
    if Meteor.isClient
      APP.justdo_i18n.setLang lang_tag, {skip_set_user_lang: true}
      @redirectToCanonicalPathIfNecessary path

    if (route_def = @getI18nRouteDef route_name)?
      # Use the route handler of the original path to parse the parameters,
      # and append to the existing list of params.
      # This is necessary because the route handler of the original path
      # is the one that knows how to parse the parameters, and will acutally use the params.
      current_params = router_this.getParams()
      path_params = Router.routes[route_name].params path
      for key, value of path_params
        if key not in ["lang", "path", "hash", "query"]
          current_params[key] = value
      router_this.setParams current_params
      route_def.routingFunction.call router_this
    else
      Router.go path, {}, {replaceState:true}

    return

  setupRouter: ->
    self = @

    Router.route "#{JustdoI18nRoutes.langs_url_prefix}/:lang", ->
      self._langRouteHandler @
      return
    , 
      name: "i18n_path_main_page"
      postMapGenerator: (sitemap) ->
        # This postMapGenerator only yield the main page route for each supported language
        for map_obj in sitemap
          if (map_obj.url is "/") and (map_obj.route.options?.translatable is true)
            map_obj.translations = []

            for lang_tag of APP.justdo_i18n.getSupportedLanguages()
              if lang_tag is JustdoI18n.default_lang
                continue
              
              translated_map_obj = _.extend {}, map_obj,
                url: self.i18nPath "/", lang_tag
                lang: lang_tag
              map_obj.translations.push translated_map_obj

        return

    Router.route "#{JustdoI18nRoutes.langs_url_prefix}/:lang/:path(.+)", ->
      self._langRouteHandler @
      return
    ,
      name: "i18n_path"
      postMapGenerator: (sitemap) ->
        for map_obj in sitemap
          if (map_obj.route.options?.translatable is true) and (map_obj.url isnt "/")
            translations = []

            for lang_tag of APP.justdo_i18n.getSupportedLanguages()
              if lang_tag is JustdoI18n.default_lang
                continue

              translated_map_obj = _.extend {}, map_obj,
                url: self.i18nPath map_obj.url, lang_tag
                lang: lang_tag

              if map_obj.canonical_to?
                # Reminder: map_obj.canonical_to is normalized by JustdoHelpers.getNormalisedUrlPathname
                translated_map_obj.canonical_to = self.i18nPath map_obj.canonical_to, lang_tag
              
              for post_map_generator_id, {predicate, generator} of self.getPostmapGenerators()
                if predicate translated_map_obj
                  generator translated_map_obj, lang_tag
                
              translations.push translated_map_obj
            
            map_obj.translations = translations
        
        return

    return


  # NOTE: this method uses the Iron Router and should not be used in the middleware level
  # Server-side redirection should happen in the middleware level
  redirectToCanonicalPathIfNecessary: (original_path, lang) ->
    canonical_path = Tracker.nonreactive => @i18nPath original_path
    
    if original_path isnt canonical_path
      Router.go canonical_path, {}, {replaceState: true}        
    
    return