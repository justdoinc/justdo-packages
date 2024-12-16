_.extend JustdoDeliveryPlanner.prototype,
  _ensureIndexesExists: -> 
    if @isProjectsCollectionEnabled()
      @tasks_collection.createIndex {"projects_collection.is_projects_collection": 1}
    return