_.extend JustdoDeliveryPlanner.prototype,
  _setupMethods: ->
    self = @

    Meteor.methods
      jdpToggleTaskIsProject: (task_id) ->
        check task_id, String

        return self.toggleTaskIsProject(task_id, @userId)

      jdpToggleTaskAsProjectsCollection: (task_id) ->
        check task_id, String
        check @userId, String
        return self.toggleTaskAsProjectsCollection(task_id, @userId)

      jdpToggleProjectsCollectionClosedState: (task_id) ->
        check task_id, String
        check @userId, String
        return self.toggleProjectsCollectionClosedState(task_id, @userId)

    return
