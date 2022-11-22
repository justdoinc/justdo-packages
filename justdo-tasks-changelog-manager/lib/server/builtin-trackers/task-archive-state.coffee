_.extend PACK.builtin_trackers,
  taskArchiveStateTracker: ->
    self = @

    self.tasks_collection.before.update (user_id, doc, field_names, modifier, options) ->
      if not _.has modifier.$set, "archived"
        return

      changelog_msg = "unarchived the task."

      if _.isDate modifier.$set.archived
        changelog_msg = "archived the task"

      self.logChange
        field: "archived"
        label: "Archived"
        change_type: "custom"
        task_id: doc._id
        by: user_id
        new_value: changelog_msg

      return
