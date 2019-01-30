_.extend JustdoTasksCollectionsManager.prototype,
  _initCollections: ->
    @tasks_collection =
      @_initTasksCollection()

    @tasks_private_data_collection =
      new Mongo.Collection("tasks_private_data", {defineMutationMethods: false})

    @tasks_private_data_collection.allowSchemaCustomFields()

    APP.collections.Tasks = @tasks_collection
    APP.collections.TasksPrivateData = @tasks_private_data_collection

    return