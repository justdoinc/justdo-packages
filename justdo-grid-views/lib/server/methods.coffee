_.extend JustdoGridViews.prototype,
  _setupMethods: ->
    self = @

    Meteor.methods
      "gridViewUpsert": (grid_view_id, options) ->
        # Options is validated in self.upsert
        self.upsert grid_view_id, options, @userId
        return
        
    return
