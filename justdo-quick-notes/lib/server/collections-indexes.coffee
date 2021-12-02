_.extend JustdoQuickNotes.prototype,
  _ensureIndexesExists: ->
    @quick_notes_collection.rawCollection().createIndex({user_id: 1, order: -1})
    return
