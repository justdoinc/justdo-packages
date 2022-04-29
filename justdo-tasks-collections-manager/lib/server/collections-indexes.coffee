_.extend JustdoTasksCollectionsManager.prototype,
  _ensureIndexesExists: ->
    @_ensureIndicesExistsForTasksCollection()
    @_ensureIndicesExistsForTasksPrivateDataCollection()

    return

  _ensureIndicesExistsForTasksCollection: ->
    # FETCH_PROJECT_TASKS_BASED_ON_PARENTS2_PARENT / FETCH_PROJECT_TASKS_BASED_ON_PARENTS2_PARENT_AND_ORDER
    @tasks_collection._ensureIndex {"project_id": 1, "parents2.parent": 1}

    # FETCH_PROJECT_TASKS_OF_SPECIFIC_USERS_INDEX
    @tasks_collection._ensureIndex {"project_id": 1, "users": 1}

    # FETCH_PROJECT_TASKS_OF_SPECIFIC_USERS_RECENTLY_UPDATED (In use by other packages)
    @tasks_collection._ensureIndex {"project_id": 1, "users": 1, "updatedAt": -1}

    # FETCH_PROJECT_TASKS_OF_SPECIFIC_USERS_BY_SEQID_ASC (In use by other packages)
    @tasks_collection._ensureIndex {"project_id": 1, "users": 1, "seqId": 1}

    # FETCH_PROJECT_TASKS_OF_SPECIFIC_USERS_WITH_RAW_UPDATED_DATE_INDEX
    @tasks_collection._ensureIndex {"project_id": 1, "users": 1, "_raw_updated_date": 1}

    # FETCH_REMOVED_TASKS_OF_SPECIFIC_USERS_INDEX
    @tasks_collection._ensureIndex {"project_id": 1, "_raw_removed_users": 1, "_raw_updated_date": 1}

    # FETCH_PROJECT_NON_REMOVED_TASKS_INDEX (In use by other packages)
    @tasks_collection._ensureIndex {"project_id": 1, "_raw_removed_date": 1}

    return

  _ensureIndicesExistsForTasksPrivateDataCollection: ->
    # FETCH_PROJECT_TASK_PRIVATE_DATA_OF_SPECIFIC_USER_INDEX
    @tasks_private_data_collection._ensureIndex {"task_id": 1, "user_id": 1, "project_id": 1}, {unique: true}
    @tasks_private_data_collection._ensureIndex {"task_id": 1, "user_id": 1}, {unique: true}

    # FETCH_PROJECT_TASKS_PRIVATE_DATA_OF_SPECIFIC_USER_FROZEN_AWARE_INDEX
    @tasks_private_data_collection._ensureIndex {"project_id": 1, "user_id": 1, "_raw_frozen": 1}

    # FETCH_PROJECT_TASKS_PRIVATE_DATA_OF_SPECIFIC_USER_FROZEN_AWARE_WITH_RAW_UPDATED_DATE_INDEX
    @tasks_private_data_collection._ensureIndex {"project_id": 1, "user_id": 1, "_raw_frozen": 1, "_raw_updated_date": 1}

    return