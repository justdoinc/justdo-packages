_.extend JustdoResourcesAvailability.prototype,
  _setupMethods: ->
    self = @

    Meteor.methods

      jdraSaveResourceAvailability: (project_id, availability, resource_user_id, task_id) ->
        return self.saveResourceAvailability(project_id, availability, resource_user_id, task_id, @userId)


    return