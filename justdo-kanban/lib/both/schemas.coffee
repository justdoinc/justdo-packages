_.extend JustdoKanban.prototype,
  _attachCollectionsSchemas: ->
    @kanbans = new Mongo.Collection "kanbans"
