_.extend JustdoRecaptcha.prototype,
  _immediateInit: ->
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