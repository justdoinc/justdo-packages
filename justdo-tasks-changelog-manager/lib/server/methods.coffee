_.extend TasksChangelogManager.prototype,
  _setupMethods: ->
    self = @

    Meteor.methods
      "undo": (activity_obj) ->
        check activity_obj.by, String
        check activity_obj._id, String
        check activity_obj.change_type, String

        # Only allow the change maker to undo changes
        if activity_obj.by isnt @userId
          return

        self.changelog_collection.update activity_obj._id,
          $set:
            undone: true
            undone_on: new Date
            change_type: activity_obj.change_type

        return

    return
