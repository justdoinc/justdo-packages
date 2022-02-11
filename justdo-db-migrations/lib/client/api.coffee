_.extend JustdoDbMigrations.prototype,
  _immediateInit: ->
    return

  _deferredInit: ->
    if @destroyed
      return

    return
