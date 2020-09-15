_.extend JustdoGridGantt.prototype,
  _immediateInit: ->
    return

  _deferredInit: ->
    if @destroyed
      return

    # Defined in methods.coffee
    @_setupMethods()

    # Defined in collections-hooks.coffee
    @_setupCollectionsHooks()

    # # Defined in publications.coffee
    # @_setupPublications()

    # # Defined in allow-deny.coffee
    # @_setupAllowDenyRules()

    # # Defined in collections-indexes.coffee
    # @_ensureIndexesExists()

    # @_registerAllowedConfs()

    return

  
