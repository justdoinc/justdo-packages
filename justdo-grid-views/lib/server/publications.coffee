_.extend JustdoGridViews.prototype,
  _setupPublications: ->
    @_publishGridViews()
    return

  _publishGridViews: ->
    self = @

    Meteor.publish "gridViews", (options) ->
      if not @userId?
        @ready()
        return

      {cleaned_val} =
        JustdoHelpers.simpleSchemaCleanAndValidate(
          @_grid_views_hierarchy_schema, # Defined in schemas.coffee
          options,
          {self: @, throw_on_error: true}
        )
      {type, justdo_id} = cleaned_val

      APP.projects.requireUserIsMemberOfProject justdo_id, @userId

      get_views_query =
        $or: [
          {
            user_id: @user_id
          },
          {
            shared: true
            "hierarchy.justdo_id": justdo_id
          }
        ]

      return self.grid_views_collection.find get_views_query

    return
