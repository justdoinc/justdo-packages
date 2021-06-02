_.extend TasksChangelogManager.prototype,
  _setupMethods: ->
    self = @

    Meteor.methods
      "undoChange": (activity_obj) ->
        check activity_obj, Object

        # Only allow the change maker to undo changes
        if activity_obj.by isnt @userId
          return

        # collection.direct used to bypass collection hook
        self.tasks_collection.direct.update activity_obj.task_id,
          $set:
            [activity_obj.field]: activity_obj.old_value

        self.changelog_collection.update activity_obj._id,
          $set:
            undone: true
            undone_on: new Date
            change_type: activity_obj.change_type

        return

    return
