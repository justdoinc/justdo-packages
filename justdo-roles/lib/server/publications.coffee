_.extend JustdoRoles.prototype,
  _setupPublications: ->
    self = @

    Meteor.publish "jdrProjectRolesAndGrps", (project_id) -> # Note the use of -> not =>, we need @userId
      check project_id, String

      return self.projectRolesAndGrpsPublicationHandler(@, project_id, @userId)

    return