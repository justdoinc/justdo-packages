_.extend JustdoGridViews.prototype,
  _immediateInit: ->
    return

  _deferredInit: ->
    if @destroyed
      return

    # Defined in methods.coffee
    @_setupMethods()

    # Defined in publications.coffee
    @_setupPublications()

    # Defined in collections-hooks.coffee
    @_setupCollectionsHooks()

    # Defined in collections-indexes.coffee
    @_ensureIndexesExists()

    return

  isUserHaveAccessToGridView: (grid_view_id, user_id) ->
    grid_view_obj = @grid_views_collection.findOne({_id: grid_view_id}, {fields: {shared: 1, hierarchy: 1, user_id: 1}})

    if grid_view_obj.user_id is user_id
      return true

    if grid_view_obj.shared
      if grid_view_obj.hierarchy.type is "site"
        return true

      if grid_view_obj.hierarchy.type is "justdo"
        return APP.projects.getProjectIfUserIsMember(grid_view_obj.hierarchy.justdo_id, user_id)?

    return false

  requireUserHasAccessToGridView: (grid_view_id, user_id) ->
    if not isUserHaveAccessToGridView grid_view_id, user_id
      throw @_error "invalid-argument", "Grid View not found"

    return true

  isUserAllowedToEditGridView: (grid_view_id, user_id) ->
    grid_view_obj = @grid_views_collection.findOne({_id: grid_view_id}, {fields: {shared: 1, hierarchy: 1, user_id: 1}})

    if grid_view_obj.user_id is user_id
      return APP.projects.getProjectIfUserIsMember(grid_view_obj.hierarchy.justdo_id, user_id)?

    if grid_view_obj.shared and grid_view_obj.hierarchy.type is "justdo"
        return APP.projects.isProjectAdmin(grid_view_obj.hierarchy.justdo_id, user_id)

    return false

  requireUserAllowedToEditGridView: (grid_view_id, user_id) ->
    if not isUserAllowedToEditGridView grid_view_id, user_id
      throw @_error "permission-denied", "Not allowed to edit Grid View"

    return true

