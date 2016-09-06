_.extend GridControlMux.prototype,
  _immediateInit: ->
    return

  _deferredInit: ->
    # Defined in methods.coffee
    @_setupMethods()

    # Defined in allow-deny.coffee
    @_setupAllowDenyRules()