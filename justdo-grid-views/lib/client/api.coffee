_.extend JustdoGridViews.prototype,
  _immediateInit: ->
    return

  _deferredInit: ->
    if @destroyed
      return

    @registerProjectHeaderButton()

    # An autorun to unsubscribe grid views when changing Justdo
    @unsubscribe_grid_view_upon_project_change_handler = Tracker.autorun =>
      JD.activeJustdoId()
      @unsubscribeGridViews()
      return

    @onDestroy =>
      @unsubscribe_grid_view_upon_project_change_handler.stop()

    return

  subscribeGridViews: (options, cb) ->
    if @destroyed
      return

    # If there is no active subscription, create a new one and attempt to stop the previous one
    # Note that subscriptions will be stopped by whenever active justdo changes, as specified in above autorun.
    if not @grid_views_subscription?.ready()
      @unsubscribeGridViews()
      @grid_views_subscription = Meteor.subscribe "gridViews", options, cb

    # Subsequent calls will refresh the subscription duration
    if @grid_view_subscription_stop_delay_handler?
      Meteor.clearTimeout @grid_view_subscription_stop_delay_handler

    # Subscription will expire after grid_view_subscription_stop_delay_ms.
    @grid_view_subscription_stop_delay_handler = Meteor.setTimeout =>
      @unsubscribeGridViews()
    , JustdoGridViews.grid_view_subscription_stop_delay_ms

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
