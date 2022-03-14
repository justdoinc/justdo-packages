_.extend JustdoGridViews.prototype,
  _setupPublications: ->
    @_publishGridViews()
    return

  _publishGridViews: ->
    self = @

    Meteor.publish "gridViews", (justdo_id) ->
      if not @userId?
        @ready()
        return

      APP.projects.requireUserIsMemberOfProject justdo_id, @userId

      grid_views_query =
        $or: [
          shared: true
          "hierarchy.type": "site"
        ,
          "hierarchy.justdo_id": justdo_id
          "hierarchy.type": "justdo"
          $or: [
            user_id: @userId
          ,
            shared: true
          ]
        ]

      return self.grid_views_collection.find grid_views_query

    return
