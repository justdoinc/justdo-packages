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

      jdpCloseProjectsCollection: (task_id) ->
        check task_id, String
        check @userId, String
        return self.closeProjectsCollection(task_id, @userId)
        
      jdpReopenProjectsCollection: (task_id) ->
        check task_id, String
        check @userId, String
        return self.reopenProjectsCollection(task_id, @userId)

    return
