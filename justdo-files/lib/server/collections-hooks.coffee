_.extend JustdoFiles.prototype,
  _setupCollectionsHooks: ->
    # Cleanup files before removing tasks, to prevent orphaned files from
    # existing in our storage
    @tasks_collection.before.remove (userId, doc) =>
      @tasks_files.remove({"meta.task_id": doc._id})

      return

    return