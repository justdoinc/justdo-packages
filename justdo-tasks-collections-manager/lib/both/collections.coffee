_.extend JustdoTasksCollectionsManager.prototype,
  _initCollections: ->
    @tasks_collection =
      @_initTasksCollection()

    @tasks_private_data_collection =
      new Mongo.Collection("tasks_private_data", {defineMutationMethods: false})

    @tasks_private_data_collection.allowSchemaCustomFields()

    APP.collections.Tasks = @tasks_collection
    APP.collections.TasksPrivateData = @tasks_private_data_collection

    if Meteor.isClient
      # The following is a pseudo collection available only in the client, it is populated
      # by grid-data-com's tasks_augmented_fields pub
      APP.collections.TasksAugmentedFields = new Mongo.Collection "tasks_augmented_fields"


    return