_.extend CustomJustdoTasksLocks.prototype,
  _setupMethods: ->
    self = @

    Meteor.methods
      jdtlToggleTaskLockedState: (task_id) ->
        check task_id, String

        return self.toggleTaskLockedState(task_id, @userId)

    return