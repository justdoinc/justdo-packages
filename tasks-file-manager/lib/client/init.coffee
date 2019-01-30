_.extend TasksFileManager.prototype,
  _immediateInit: ->
    # Depend on filestack-base to load filepicker
    return

  _deferredInit: ->
    @_setupPasteEventListener()

    return
