_.extend PACK.builtin_trackers,
  removeTaskTracker: ->
    self = @

    self.tasks_collection.before.remove (userId, doc) ->
      if _.isString doc._id
        self.changelog_collection.remove {task_id: doc._id}
      return true