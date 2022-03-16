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

  isUserAllowedToEditGridView: (grid_view_id, user_id) ->
    grid_view_obj = @grid_views_collection.findOne({_id: grid_view_id}, {fields: {shared: 1, hierarchy: 1, user_id: 1}})

    if grid_view_obj.user_id is user_id
      if grid_view_obj.hierarchy.type is "site"
        return true
      # If user owns the grid view, the user must also be a member of the Justdo tied to the grid view to edit
      return APP.projects.getProjectIfUserIsMember(grid_view_obj.hierarchy.justdo_id, user_id)?

    # If the grid view is tied to a JustDo, if it is SHARED we ALSO allow admins to edit the grid view
    if grid_view_obj.shared and grid_view_obj.hierarchy.type is "justdo"
      return APP.projects.isProjectAdmin(grid_view_obj.hierarchy.justdo_id, user_id)

    return false

  requireUserAllowedToEditGridView: (grid_view_id, user_id) ->
    if not @isUserAllowedToEditGridView grid_view_id, user_id
      throw @_error "permission-denied", "Not allowed to edit Grid View"

    return true

  upsert: (grid_view_id, options, user_id) ->
    # XXX Check options better

    if _.isEmpty options
      throw @_error "missing-argument", "There's nothing to update/insert"

    # Update
    if grid_view_id?
      @requireUserAllowedToEditGridView grid_view_id, user_id

      modifier = _.omit options, "hierarchy"
      if options.hierarchy?
        # XXX hierarchy overrides fully.
        for field_id, field_val of options.hierarchy
          modifier["hierarchy.#{field_id}"] = field_val

      return @grid_views_collection.update grid_view_id, {$set: modifier}
    # Insert
    else
      # XXX Need to check for type, the hierarchy existence must be obvious
      if options.hierarchy?.justdo_id?
        if options.shared
          # Only Justdo admins can share Views
          APP.projects.requireProjectAdmin options.hierarchy.justdo_id, user_id
        else
          # Only Justdo member can create a view under the Justdo
          APP.projects.requireUserIsMemberOfProject options.hierarchy.justdo_id, user_id
      options.user_id = user_id

      return @grid_views_collection.insert options

    return
