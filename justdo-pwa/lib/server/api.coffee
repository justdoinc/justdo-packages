_.extend JustdoPwa.prototype,
  _immediateInit: ->
    @_setupManifestInjection()
    return

  _deferredInit: ->
    if @destroyed
      return

    # Defined in methods.coffee
    @_setupMethods()

    # Defined in publications.coffee
    @_setupPublications()

    # Defined in collections-hooks.coffee
    @_setupCollectionsHooks()

    # Defined in collections-indexes.coffee
    @_ensureIndexesExists()

    return

  _generateManifest: ->
    manifest = 
      name: "JustDo"
      short_name: "JustDo"
      start_url: "/"
      display: "minimal-ui"
      background_color: "#000000"
      theme_color: "#1875d2"
      icons: [
        src: "#{JustdoHelpers.getCDNUrl "/layout/logos-ext/justdo_favicon.ico"}"
        sizes: "16x16 24x24 32x32 48x48 64x64"
        type: "image/x-icon"
      ]

    return manifest

  _setupManifestInjection: ->
    WebApp.connectHandlers.use (req, res, next) =>
      req.dynamicHead = req.dynamicHead or ""
    
      req.dynamicHead += """
      <link rel="manifest" href="/manifest.json" />
      """
    
      next()
      
      return
    
    WebApp.connectHandlers.use "/manifest.json", (req, res, next) =>
      res.writeHead 200, {"Content-Type": "application/json"}
      res.end JSON.stringify(@_generateManifest())
      return
    
    return