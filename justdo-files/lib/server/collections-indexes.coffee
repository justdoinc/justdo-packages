_.extend JustdoFiles.prototype,
  _ensureIndexesExists: ->
    # TASKS_FILES_COLLECTION_TASK_ID_INDEX
    @tasks_files.rawCollection().createIndex {"meta.task_id": 1}

    return
