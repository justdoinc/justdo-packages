_.extend JustdoQuickNotes.prototype,
  _ensureIndexesExists: ->
    # QUICK_NOTES_REORDER_PUT_BEFORE_QUERY_INDEX
    await @quick_notes_collection.createIndexAsync({user_id: 1, order: -1})
    return
