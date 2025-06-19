_.extend JustdoDeliveryPlanner.prototype,
  _ensureIndexesExists: -> 
    @tasks_collection.createIndex {"projects_collection.projects_collection_type": 1}
    return