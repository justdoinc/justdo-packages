_.extend JustdoSystemRecords.prototype,
  _immediateInit: ->
    return

  _deferredInit: ->
    if @destroyed
      return

    return
