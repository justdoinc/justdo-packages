_.extend JustdoGridViews.prototype,
  _immediateInit: ->
    return

  _deferredInit: ->
    if @destroyed
      return
    @registerProjectHeaderButton()
    
    return

  subscribeGridViews: (options, cb) ->
    if @destroyed
      return

    if @grid_views_subscription?
      @grid_views_subscription.stop()

    @grid_views_subscription = Meteor.subscribe "gridViews", options, cb

    return @grid_views_subscription

  unsubscribeGridViews: ->
    @grid_views_subscription?.stop()
    return

  registerProjectHeaderButton: ->
    JD.registerPlaceholderItem "grid-views-dropdown-button",
      data:
        template: "grid_views_dropdown_button"
        template_data: {}

      domain: "project-left-navbar"
      position: 100
