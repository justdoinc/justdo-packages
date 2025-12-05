_.extend JustdoDeliveryPlanner.prototype,
  _ensureIndexesExists: -> 
    @tasks_collection.createIndex {"projects_collection.projects_collection_type": 1}

    # PROJECTS_OWNED_BY_USER_AND_STATE_INDEX
    @tasks_collection.createIndex {
      [JustdoDeliveryPlanner.task_is_project_field_name]: 1
      "owner_id": 1
      "users": 1
      "state": 1
    },
    {sparse: true}
    return