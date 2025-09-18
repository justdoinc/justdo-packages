_.extend JustdoAccounts.prototype,
  _immediateInit: ->
    @_setupOAuthRegistry()
    return

  _deferredInit: ->
    # Defined in methods.coffee
    @_setupMethods()

    # Defined in allow-deny.coffee
    @_setupAllowDenyRules()

    # Defined in collection-hooks.coffee
    @_setupCollectionsHooks()

    # Defined in publications.coffee
    @_setupPublications()

    @_setupDbMigrations()

    return