_.extend JustdoGridViews.prototype,
  _setupPublications: ->
    @_publishGridViews()
    return

  _publishGridViews: ->
    self = @

    # XXX needs to follow description here: https://app-beta.justdo.com/p/9pfc4T3NghhPhLqH4#&t=main&p=/J2TEjZSg9rgxAdvJJ/WXHPgrWsoAnctz2d2/jLE5zGinb9fWMZcfo/qFejdeF6dfMmy9ir6/
    Meteor.publish "gridViews", (options) ->
      # Right now this publication deals ONLY with the case of type = justdo, the rest will be done in the future.

      # XXX better checking for value received
      # {type, justdo_id} = options
      # check type, String
      # check justdo_id, String

      if not @userId?
        @ready()
        return

      APP.projects.requireUserIsMemberOfProject justdo_id, @userId

      # XXX The following shouldn't regard type=site (for now)
      grid_views_query =
        $or: [
          {
            shared: true
            "hierarchy.type": "site"
          }
        ,
          {
            "hierarchy.justdo_id": justdo_id
            "hierarchy.type": "justdo"
            $or: [
              {
                user_id: @userId
              }
            ,
              {
                shared: true
              }
            ]
          }
        ]

      return self.grid_views_collection.find grid_views_query

    return
