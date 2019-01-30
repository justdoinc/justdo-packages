_.extend JustdoTasksCollectionsManager.prototype,
  _immediateInit: ->
    return

  _deferredInit: ->
    if @destroyed
      return

    return
