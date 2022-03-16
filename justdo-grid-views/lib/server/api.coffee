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

  _insertGridViewOptionsSchema: new SimpleSchema
    title:
      type: String
      optional: true

    deleted:
      type: Boolean
      optional: true

    hierarchy:
      type: Object

    "hierarchy.type":
      type: String
      allowedValues: ["site", "justdo"]

    "hierarchy.justdo_id":
      type: String
      optional: true
      autoValue: ->
        if @field("hierarchy.type").value is "justdo"
          return
        return @unset()

    view:
      type: String

    shared:
      type: Boolean
      optional: true
  _insertGridView: (options, user_id) ->
    {cleaned_val} =
      JustdoHelpers.simpleSchemaCleanAndValidate(
        @_insertGridViewOptionsSchema,
        options,
        {self: @, throw_on_error: true}
      )

    if cleaned_val.type is "justdo"
      if cleaned_val.shared
        # Only Justdo admins can share Views
        APP.projects.requireProjectAdmin options.hierarchy.justdo_id, user_id
      else
        # Only Justdo member can create a view under the Justdo
        APP.projects.requireUserIsMemberOfProject options.hierarchy.justdo_id, user_id

    cleaned_val.user_id = user_id

    return @grid_views_collection.insert cleaned_val

  _updateGridViewOptionsSchema = new SimpleSchema
    title:
      type: String
      optional: true

    deleted:
      type: Boolean
      optional: true

    view:
      type: String

    shared:
      type: Boolean
      optional: true
  _updateGridView: (grid_view_id, options) ->
    @requireUserAllowedToEditGridView grid_view_id, user_id

    {cleaned_val} =
      JustdoHelpers.simpleSchemaCleanAndValidate(
        @_updateGridViewOptionsSchema,
        options,
        {self: @, throw_on_error: true}
      )

    if _.isEmpty cleaned_val
      throw @_error "missing-argument", "There's nothing to update/insert"

    return @grid_views_collection.update grid_view_id, {$set: cleaned_val}

  upsert: (grid_view_id, options, user_id) ->
    # Checks on options will be performed in the corresponding APIs
    check grid_view_id, Match.Maybe String
    check user_id, String

    # insert
    if not grid_view_id?
      return @_insertGridView options, user_id

    # update
    return @_updateGridView grid_view_id, options, user_id
