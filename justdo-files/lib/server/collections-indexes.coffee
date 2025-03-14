_.extend JustdoFiles.prototype,
  _ensureIndexesExists: ->
    # TASKS_FILES_COLLECTION_TASK_ID_INDEX
    @tasks_files.collection._ensureIndex {"meta.task_id": 1}

    # AVATARS_COLLECTION_USERID_INDEX
    @avatars_collection.collection._ensureIndex {userId: 1}

    # TASKS_FILES_COLLECTION_PROJECT_ID_UPLOAD_DATE_INDEX
    @tasks_files.collection._ensureIndex {"meta.project_id": 1, "meta.upload_date": 1}
    return
