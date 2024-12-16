_.extend JustdoDeliveryPlanner.prototype,
  _ensureIndexesExists: -> 
    if @isProjectsCollectionEnabled()
      @tasks_collection.createIndex {"projects_collection.projects_collection_type": 1}
    return