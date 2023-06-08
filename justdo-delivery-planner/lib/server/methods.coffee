_.extend JustdoDeliveryPlanner.prototype,
  _setupMethods: ->
    self = @

    Meteor.methods
      jdpToggleTaskIsProject: (task_id) ->
        check task_id, String

        return self.toggleTaskIsProject(task_id, @userId)

    return
