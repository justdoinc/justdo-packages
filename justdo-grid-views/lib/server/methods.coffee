_.extend JustdoGridViews.prototype,
  _setupMethods: ->
    self = @

    Meteor.methods
      "gridViewUpsert": (grid_view_id, options) ->
        check grid_view_id, Match.Maybe(String)
        check @userId, String
        # Options is validated in self.upsert

        self.upsert grid_view_id, options, @userId
        return
        
    return
