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

  # Despite grid view owner can edit/delete grid views, only Justdo admins can share/unshare grid views (if the hierarchy is "justdo")
  # hence there are two seperate APIs for checking edit rights and share rights.
  isUserAllowedToShareGridView: (grid_view_id, user_id) ->
    grid_view_obj = @grid_views_collection.findOne(grid_view_id, {fields: {shared: 1, hierarchy: 1, user_id: 1}})

    if not grid_view_obj?
      throw @_error "grid-view-not-found", "Grid view does not exist"

    if grid_view_obj.hierarchy?.type is "justdo" and (grid_view_obj.shared or grid_view_obj.user_id is user_id) 
      return APP.projects.isProjectAdmin(grid_view_obj.hierarchy.justdo_id, user_id)

    return false

  requireUserAllowedToShareGridView: (grid_view_id, user_id) ->
    if not @isUserAllowedToShareGridView grid_view_id, user_id
      throw @_error "permission-denied", "Not allowed to share Grid View"

    return true

  isUserAllowedToEditGridView: (grid_view_id, user_id) ->
    grid_view_obj = @grid_views_collection.findOne({_id: grid_view_id}, {fields: {shared: 1, hierarchy: 1, user_id: 1}})

    if not grid_view_obj?
      throw @_error "grid-view-not-found", "Grid view does not exist"

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

  _insertGridViewOptionsSchema: new SimpleSchema(JustdoGridViews.prototype._grid_views_schema).omit "user_id", "created", "updated"
  _insertGridView: (options, user_id) ->
    {cleaned_val} =
      JustdoHelpers.simpleSchemaCleanAndValidate(
        @_insertGridViewOptionsSchema,
        options,
        {self: @, throw_on_error: true}
      )
    options = cleaned_val

    if options.type is "justdo"
      if options.shared
        # Only Justdo admins can share Views
        @requireUserAllowedToShareGridView options.hierarchy.justdo_id, user_id
      else
        # Only Justdo member can create a view under the Justdo
        APP.projects.requireUserIsMemberOfProject options.hierarchy.justdo_id, user_id

    options.user_id = user_id

    return @grid_views_collection.insert options

  # Upon creating a schema object with an array of objects passed, the object will be extended.
  _updateGridViewOptionsSchema: new SimpleSchema([JustdoGridViews.prototype._grid_views_schema, {view: {optional: true}}]).pick "view", "title", "deleted", "shared"
  _updateGridView: (grid_view_id, options, user_id) ->
    @requireUserAllowedToEditGridView grid_view_id, user_id

    {cleaned_val} =
      JustdoHelpers.simpleSchemaCleanAndValidate(
        @_updateGridViewOptionsSchema,
        options,
        {self: @, throw_on_error: true}
      )
    options = cleaned_val

    if _.isEmpty options
      throw @_error "missing-argument", "There's nothing to update/insert"

    if options.shared?
      @requireUserAllowedToShareGridView grid_view_id, user_id

    return @grid_views_collection.update grid_view_id, {$set: options}

  upsert: (grid_view_id, options, user_id) ->
    # Checks on options will be performed in the corresponding APIs
    check grid_view_id, Match.Maybe String
    check user_id, String

    # insert
    if _.isEmpty grid_view_id
      return @_insertGridView options, user_id

    # update
    return @_updateGridView grid_view_id, options, user_id
