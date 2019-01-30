removeFilesOfRemovedTaskHook = (userId, doc) ->
  if (doc_files = doc.files)?
    _.each doc_files, (file) ->
      APP.filestack_base.cleanupRemovedFile file

      return

  return

_.extend TasksFileManager.prototype,
  _setupCollectionsHooks: ->
    # Cleanup files before removing tasks, to prevent orphaned files from
    # existing in our storage
    @tasks_collection.before.remove removeFilesOfRemovedTaskHook

    # Cleanup files before permanently removing tasks from the removed projects
    # items archive, to prevent orphaned files from existing in our storage
    #
    # Note, that when items are moved to the archive, the remove operation from
    # the regular items collection is done in a way that doesn't trigger
    # the above @tasks_collection.before hook (by using the mongo connection
    # directly). To allow tasks restore with their files.
    @removed_projects_tasks_archive_collection.before.remove removeFilesOfRemovedTaskHook
