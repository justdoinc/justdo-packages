_.extend JustdoPermissions.prototype,
  _immediateInit: ->
    return

  _deferredInit: ->
    if @destroyed
      return

    return
