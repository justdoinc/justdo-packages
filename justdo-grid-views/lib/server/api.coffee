_.extend JustdoGridViews.prototype,
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

  isUserHasAccessToGridView: (grid_view_id, user_id) ->
    return @grid_views_collection.findOne({_id: grid_view_id, user_id: user_id}, {fields: {_id: 1}})?

  requireUserHasAccessToGridView: (grid_view_id, user_id) ->
    if not requireUserHasAccessToGridView grid_view_id, user_id
      throw @_error "invalid-argument", "Grid View not found"

    return true

