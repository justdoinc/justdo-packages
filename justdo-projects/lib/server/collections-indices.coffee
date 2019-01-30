_.extend Projects.prototype,
  _ensureIndicesExists: ->
    @_ensureIndicesExistsProjects()

    return

  _ensureIndicesExistsProjects: ->
    # Ensure indices on the projects collection
    @projects_collection._ensureIndex {"members.user_id": 1}
    @projects_collection._ensureIndex {"members.user_id": 1, "members.is_admin": 1}
    @projects_collection._ensureIndex {"_id": 1, "members.user_id": 1}

    return
