_.extend JustdoChat.prototype,
  _immediateInit: ->
    for type, conf of share.channel_types_server_specific_conf
      if conf._immediateInit?
        conf._immediateInit.call(@)

    return

  _deferredInit: ->
    if @destroyed
      return

    for type, conf of share.channel_types_server_specific_conf
      if conf._deferredInit?
        conf._deferredInit.call(@)

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