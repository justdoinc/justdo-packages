_.extend TasksFileManager.prototype,
  _immediateInit: ->
    @filestack_secret = @options.secret or throw @_error "api-secret-required"
    @filestack_api_key = @options.api_key or throw @_error "api-key-required"

  _deferredInit: ->
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
