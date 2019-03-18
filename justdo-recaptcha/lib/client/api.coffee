_.extend JustdoRecaptcha.prototype,
  _immediateInit: ->
    @addJustdoAccountsPasswordExtensions()

    return

  _deferredInit: ->
    if @destroyed
      return

    return

  getResponse: ->
    if @supported
      grecaptcha.getResponse()

      return

    return ""