_.extend JustdoUserActivePosition.prototype,
  _ensureIndexesExists: ->
    await @users_active_positions_ledger_collection.createIndexAsync({"time": -1})

    # ACTIVE_POSITIONS_LEDGER_COLLECTION_ORG_ACTIVE_USER_INDEX
    await @users_active_positions_ledger_collection.createIndexAsync({"UID": 1, "justdo_id": 1, "last_active_time": -1, "time": 1})

    # ACTIVE_POSITIONS_LEDGER_COLLECTION_UID_TIME_INDEX
    await @users_active_positions_ledger_collection.createIndexAsync({"UID": 1, "time": 1})

    return
