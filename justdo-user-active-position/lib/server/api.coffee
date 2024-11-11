_.extend JustdoUserActivePosition.prototype,
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

    @_setupDbMigrations()

    return

  logPos: (pos, user_id) ->
    check pos, JustdoUserActivePosition.schemas.PosObjectSchema
    check user_id, Match.Maybe(String)

    if not user_id? or _.isEmpty user_id
      # At the moment we don't log non-logged-in
      return

    doc = _.extend {}, pos, {UID: user_id, SSID: APP.justdo_analytics.getSSID()}

    @users_active_positions_ledger_collection.insert(doc)

    return
