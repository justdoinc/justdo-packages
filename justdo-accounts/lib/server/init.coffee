_.extend JustdoAccounts.prototype,
  _immediateInit: ->
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

    return