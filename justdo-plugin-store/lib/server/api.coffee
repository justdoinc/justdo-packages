_.extend JustdoPluginStore.prototype,
  _immediateInit: ->
    @_setupConnectHandlers()
    return

  _deferredInit: ->
    if @destroyed
      return

    # Defined in methods.coffee
    @_setupMethods()

    # Defined in publications.coffee
    @_setupPublications()

    # Defined in allow-deny.coffee
    @_setupAllowDenyRules()

    # Defined in collections-hooks.coffee
    @_setupCollectionsHooks()

    # Defined in collections-indexes.coffee
    @_ensureIndexesExists()

    return

  _setupConnectHandlers: ->
    # This middleware does the following jobs:
    # 1. redirects /plugins/c/{JustdoPluginStore.default_category} to /plugins
    # 2. returns 404 if the category or plugin doesn't exist
    # Note that we don't handle /plugins/p and /plugins/c here because they aren't registered and will return 404 by default.
    WebApp.connectHandlers.use (req, res, next) =>
      url = req.url
      if APP.justdo_i18n_routes?
        data = APP.justdo_i18n_routes.getStrippedPathAndLangFromReq req
        url = data.processed_path
        lang = data.lang_tag or JustdoI18n.default_lang
      if APP.justdo_seo?
        url = APP.justdo_seo.getPathWithoutHumanReadableParts url
      
     # The construction of url_obj is necessary to keep the search params and other parts of the url intact when redirecting
      url_obj = new URL url, JustdoHelpers.getRootUrl()
      
      base_path = "/plugins"
      category_base_path = "#{base_path}/c"
      plugins_base_path = "#{base_path}/p"
      
      # Handles categories
      if url_obj.pathname.startsWith category_base_path
        if url_obj.pathname is "#{category_base_path}/#{JustdoPluginStore.default_category}"
          # Assign the path to url obj to maintain the search params and other parts of the url
          url_obj.pathname = base_path
          if APP.justdo_i18n_routes?
            url_obj.pathname = APP.justdo_i18n_routes.i18nPath base_path, lang
            
          res.writeHead 301,
            Location: url_obj
          res.end()
          return
        
        url_category = @getCategoryOrPluginIdFromPath url_obj.pathname
        if not @isCategoryExists url_category
          res.writeHead 404
          # XXX We should probably return a nicely-styled static 404 page here, like the one on Youtube
          res.end "404 Not Found"
          return
      
      # Handles plugins
      if url_obj.pathname.startsWith plugins_base_path
        url_plugin = @getCategoryOrPluginIdFromPath url_obj.pathname
        if not @isPluginExists url_plugin
          res.writeHead 404
          # XXX We should probably return a nicely-styled static 404 page here, like the one on Youtube
          res.end "404 Not Found"
          return

      next()
      return
  
  getAllCategories: -> share.store_db.categories

  getAllPlugins: -> share.store_db.plugins
