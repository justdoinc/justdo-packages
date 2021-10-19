_.extend TasksChangelogManager.prototype,
  _setupMethods: ->
    self = @

    Meteor.methods
      "undoActivity": (activity_log_id) ->
        check activity_log_id, String
        
        self.undoActivity activity_log_id, @userId
        return

    return
