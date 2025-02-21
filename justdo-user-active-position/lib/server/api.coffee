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

  # Returns a cursor for the recent active positions ledger docs
  #
  # @param {String} performer_id - The performer ID
  # @returns {Mongo.Cursor} A cursor for the recent active positions ledger docs
  getRecentActivePositionsLedgerDocCursor: (performer_id) ->
    check performer_id, String

    query = 
      UID: 
        $ne: performer_id
      time: 
        $gte: new Date(Date.now() - JustdoUserActivePosition.idle_time_to_consider_session_ended)
      private:
        $ne: true
    query_options = 
      sort: 
        time: -1
      fields:
        path: 1
        UID: 1
        justdo_id: 1
        field: 1
        time: 1

    cursor = @users_active_positions_ledger_collection.find(query, query_options)

    return cursor

  # Hide user's active position from other users
  hideUserActivePosition: (user_id) ->
    check user_id, String

    Meteor.users.update(user_id, {$set: {"justdo_user_active_position.hide_user_active_position": true}})

    return

  # Show user's active position to other users
  showUserActivePosition: (user_id) ->
    check user_id, String

    Meteor.users.update(user_id, {$unset: {"justdo_user_active_position.hide_user_active_position": true}})

    return
