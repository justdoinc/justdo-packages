_.extend JustdoRoles.prototype,
  _ensureIndexesExists: ->
    # PROJECT_ROLES_AND_GROUPS_INDEX
    @projects_roles_and_grps_collection.rawCollection().createIndex({project_id: 1}, {unique: true})

    return