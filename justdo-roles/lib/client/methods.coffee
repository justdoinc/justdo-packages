_.extend JustdoRoles.prototype,
  setProjectRolesAndGroups: (project_id, roles_and_groups_obj, cb) ->
    Meteor.call "jdrSetProjectRolesAndGroups", project_id, roles_and_groups_obj, cb

    return

  performRegionalManagerEdits: (project_id, edits, cb) ->
    Meteor.call "jdrPerformRegionalManagerEdits", project_id, edits, cb

    return
