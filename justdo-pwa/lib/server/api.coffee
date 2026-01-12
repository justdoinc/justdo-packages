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

  _getManifestName: ->
    root_url = JustdoHelpers.getRootUrl()
    
    try
      URL = JustdoHelpers.getURL()
      url_obj = new URL root_url
      hostname = url_obj.hostname
    catch
      return "JustDo"
    
    # Remove www. prefix if present
    hostname = hostname.replace /^www\./, ""
    
    # Case 1: Root domain justdo.com -> "JustDo"
    if hostname is "justdo.com"
      return "JustDo"
    
    # Case 2: Subdomain of justdo.com (e.g., app-fair-wood.justdo.com, premium.justdo.com)
    justdo_subdomain_match = hostname.match /^([^.]+)\.justdo\.com$/
    if justdo_subdomain_match
      subdomain = justdo_subdomain_match[1]
      # Convert "app-fair-wood" to "Fair Wood", "premium" to "Premium"
      # Remove "app-" prefix if present
      subdomain = subdomain.replace /^app-/, ""
      # Convert dashes to spaces and capitalize each word
      formatted_subdomain = subdomain
        .split("-")
        .map((word) -> JustdoHelpers.ucFirst(word))
        .join(" ")
      return "JustDo - #{formatted_subdomain}"
    
    # Case 3: Non-justdo.com domain (e.g., justdo.kompletit.com)
    return "JustDo - #{hostname}"

  _generateManifest: ->
    manifest = 
      name: @_getManifestName()
      short_name: @_getManifestName()
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