_.extend JustdoChecklist.prototype,
  _setupMethods: ->
    self = @

    Meteor.methods
      jdchToggleChecklistSwitch: (task_id) ->
        check task_id, String

        return self.toggleChecklistSwitch(task_id, @userId)

      jdchToggleCheckItemSwitch: (task_id) ->
        check task_id, String

        return self.toggleCheckItemSwitch(task_id, @userId)

    return