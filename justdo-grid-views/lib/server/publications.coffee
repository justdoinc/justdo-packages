_.extend JustdoGridViews.prototype,
  _setupPublications: ->
    @_publishGridViews()
    return

  _publishGridViews: ->
    self = @

    Meteor.publish "gridViews", (options) ->
      # Right now this publication deals ONLY with the case of type = justdo, the rest will be done in the future.
      if not @userId?
        throw @_error "login-required"

      {type, justdo_id} = options
      check type, String
      check justdo_id, String

      APP.projects.requireUserIsMemberOfProject justdo_id, @userId

      grid_views_query =
        "hierarchy.type": "justdo"
        "hierarchy.justdo_id": justdo_id
        $or: [
          {
            user_id: @userId
          }
        ,
          {
            shared: true
          }
        ]

      return self.grid_views_collection.find grid_views_query

    return
