_.extend TasksChangelogManager.prototype,
  _setupCollectionsHooks: ->
    self = @

    removeChangelogsOfRemovedTaskHook = (userId, doc) ->
      self.changelog_collection.remove({task_id: doc._id})

      return

    # Cleanup changelogs before removing tasks, to prevent orphaned changelogs from
    # existing in our storage
    self.tasks_collection.before.remove removeChangelogsOfRemovedTaskHook

    # Cleanup changelog items before permanently removing tasks from the removed projects
    # items archive, to prevent orphaned changelog from existing in our storage.
    #
    # Note, that when items are moved to the archive, the remove operation from
    # the regular items collection is done in a way that doesn't trigger
    # the above self.tasks_collection.before hook (by using the mongo connection
    # directly). To allow tasks restore without losing changelog history.
    self.removed_projects_tasks_archive_collection.before.remove removeChangelogsOfRemovedTaskHook