_.extend JustdoRecaptcha.prototype,
  _immediateInit: ->
    if @supported
      @addJustdoAccountsPasswordExtensions()

    return

  _deferredInit: ->
    if @destroyed
      return

    return

  getResponse: ->
    if @supported
      try
        return grecaptcha.getResponse()
      catch e
        return ""

    return ""