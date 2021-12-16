_.extend JustdoSystemRecords.prototype,
  _immediateInit: ->
    return

  _deferredInit: ->
    if @destroyed
      return

    # Defined in methods.coffee
    @_setupMethods()

    # Defined in publications.coffee
    @_setupPublications()

    # Defined in collections-hooks.coffee
    @_setupCollectionsHooks()

    # Defined in collections-indexes.coffee
    @_ensureIndexesExists()

    return

  setRecord: (id, doc={}) ->
    @system_records_collection.upsert id, doc
    return

  getRecord: (id) ->
    return @system_records_collection.findOne(id)
