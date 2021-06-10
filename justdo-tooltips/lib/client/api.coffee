_.extend JustdoTooltips.prototype,
  _immediateInit: ->
    return

  _deferredInit: ->
    if @destroyed
      return

    return