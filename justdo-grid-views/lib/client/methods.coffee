_.extend JustdoGridViews.prototype,
  upsert: (grid_view_id, options, cb) ->
    modifiers = _.extend {}, options
    if not _.isString modifiers.view
      modifiers.view = EJSON.stringify modifiers.view

    Meteor.call "gridViewUpsert", grid_view_id, modifiers, cb
    return
