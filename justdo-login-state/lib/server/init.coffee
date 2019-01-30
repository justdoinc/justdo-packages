_.extend JustdoLoginState.prototype,
  _immediate_init: ->
    return

  _init: ->
    # Defined in methods.coffee
    @_setupMethods()

    # Defined in allow-deny.coffee
    @_setupAllowDenyRules()

    # Setup the data injections
    @_setupDataInjections()