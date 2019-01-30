_.extend JustdoRoles.prototype,
  _setupMethods: ->
    self = @

    Meteor.methods
      jdrSetProjectRolesAndGroups: (project_id, roles_and_groups_obj) ->
        check project_id, String
        check roles_and_groups_obj, Object # thoroughly checked by the self.setProjectRolesAndGroups()

        return self.setProjectRolesAndGroups(project_id, roles_and_groups_obj, @userId)

      jdrPerformRegionalManagerEdits: (project_id, edits) ->
        check project_id, String
        check edits, Object # thoroughly checked by the self.setProjectRolesAndGroups()

        return self.performRegionalManagerEdits(project_id, edits, @userId)

    return