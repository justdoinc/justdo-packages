_.extend JustdoTaskType.prototype,
  _attachCollectionsSchemas: ->
    Schema =
      "task-type::<>":
        type: [String]
        client_only: true
        optional: true

    @tasks_collection.attachSchema Schema

    return