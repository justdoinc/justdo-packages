_.extend JustdoGridViews.prototype,
  upsert: (grid_view_id, options, cb) ->
    Meteor.call "gridViewUpsert", grid_view_id, options, cb
    return
