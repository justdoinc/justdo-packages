_.extend JustdoGridViews.prototype,
  _immediateInit: ->
    return

  _deferredInit: ->
    if @destroyed
      return

    return

  subscribeGridViews: (justdo_id, cb) ->
    if @destroyed
      return

    if @grid_views_subscription?
      @grid_views_subscription.stop()

    @grid_views_subscription = Meteor.subscribe "gridViews", justdo_id, cb

    return @grid_views_subscription

  unsubscribeGridViews: ->
    @grid_views_subscription?.stop()
    return
