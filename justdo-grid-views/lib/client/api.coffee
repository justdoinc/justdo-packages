_.extend JustdoGridViews.prototype,
  _immediateInit: ->
    return

  _deferredInit: ->
    if @destroyed
      return

    return

  subscribeGridViews: (options, cb) ->
    if @destroyed
      return

    if @grid_views_subscription?.ready()
      @grid_views_subscription.stop()

    @grid_views_subscription = Meteor.subscribe "gridViews", options, cb

    return @grid_views_subscription

  unSubscribeGridViews: ->
    @grid_views_subscription.stop()
    return
