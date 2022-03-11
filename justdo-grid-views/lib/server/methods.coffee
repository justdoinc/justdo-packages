_.extend JustdoGridViews.prototype,
  _setupMethods: ->
    self = @

    Meteor.methods
      "gridViewUpsert": (grid_view_id, options) ->
        check grid_view_id, Match.Maybe(String)
        check @userId, String

        self.upsert grid_view_id, options, @userId
        return
        
    return
