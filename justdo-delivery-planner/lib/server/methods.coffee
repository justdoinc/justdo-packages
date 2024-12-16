_.extend JustdoDeliveryPlanner.prototype,
  _setupMethods: ->
    self = @

    Meteor.methods
      jdpToggleTaskIsProject: (task_id) ->
        check task_id, String

        return self.toggleTaskIsProject(task_id, @userId)

      jdpSetTaskProjectCollectionType: (task_id, type_id) ->
        check task_id, String
        check type_id, String
        check @userId, String
        return self.setTaskProjectCollectionType(task_id, type_id, @userId)
      
      jdpUnsetTaskProjectCollectionType: (task_id) ->
        check task_id, String
        check @userId, String
        return self.unsetTaskProjectCollectionType(task_id, @userId)

      jdpToggleProjectsCollectionClosedState: (task_id) ->
        check task_id, String
        check @userId, String
        return self.toggleProjectsCollectionClosedState(task_id, @userId)

    return
