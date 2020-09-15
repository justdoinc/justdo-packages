_.extend JustdoGridGantt.prototype,
  _immediateInit: ->
    # Defined in db-migrations.coffee
    # @_setupDbMigrations()
    
    return

  _deferredInit: ->
    if @destroyed
      return

    return
  
  _setupCollectionsHooks: ->

    return