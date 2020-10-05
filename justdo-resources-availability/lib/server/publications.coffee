_.extend JustdoResourcesAvailability.prototype,
  _setupPublications: ->
    @_publishResourceAvailability()
    return

  _publishResourceAvailability: ->
    self = @
    Meteor.publish "jd-resource-availability", (project_id) ->
      user_id = @userId
      project = APP.collections.Projects.findOne {_id: project_id }
      if not project?
        throw self._error "not-project-member"
      if not _.findWhere(project.members, {user_id: user_id })?
        throw self._error "not-project-member"
      return APP.collections.Projects.find {"_id": project_id}, {fields: {"#{JustdoResourcesAvailability.project_custom_feature_id}":1}}
    return