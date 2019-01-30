_.extend TasksChangelogManager.prototype,
  _ensureIndexesExists: ->
    @changelog_collection._ensureIndex {"task_id": 1}