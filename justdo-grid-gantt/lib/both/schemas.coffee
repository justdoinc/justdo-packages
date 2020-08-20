_.extend JustdoGridGantt.prototype,
  _attachCollectionsSchemas: ->
    # On the client, we set pseudo custom field, but still, to ensure correct
    # types we also set schema here.

    return