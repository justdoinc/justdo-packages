_.extend JustdoResourcesAvailability.prototype,
  _setupMethods: ->
    self = @

    Meteor.methods {

      jdraSaveResourceAvailability: (project_id, availability, user_id, task_id) ->
        return self.saveResourceAvailability(@userId, project_id, availability, user_id, task_id)
    }

    return