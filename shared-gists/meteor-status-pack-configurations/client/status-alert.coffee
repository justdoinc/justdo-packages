status_messages =
  connected: "Connected"
  connecting: "Connecting..."
  failed: "Connection lost"
  waiting: "Connection lost,"
  offline: "Offline mode."

Template.status_alert.onCreated ->
  @should_show_status_rv = new ReactiveVar(false)
  @show_delay_handle = null

  @setShowDelayHandle = =>
    # If already showing or delay pending, do nothing
    is_showing = Tracker.nonreactive => @should_show_status_rv.get()
    is_going_to_show = @show_delay_handle?

    if (not is_showing) and (not is_going_to_show)
      # Start delay before showing
      @show_delay_handle = Meteor.setTimeout =>
        @should_show_status_rv.set(true)
        @show_delay_handle = null
        return
      , Status.getShowDelay()

    return

  @clearShowDelayHandle = =>
    if @show_delay_handle?
      Meteor.clearTimeout(@show_delay_handle)
      @show_delay_handle = null
    return

  @setShouldShowStatus = (should_show) =>
    if should_show
      # @should_show_status_rv.set(true) is done in @setShowDelayHandle()
      @setShowDelayHandle()
    else
      # Clear any pending delay and hide immediately
      @clearShowDelayHandle()
      @should_show_status_rv.set(false)

    return

  @autorun =>
    meteor_status = Meteor.status()
    current_status = meteor_status.status

    should_show = false
    if current_status in ["failed", "waiting", "offline"]
      should_show = true
    else if meteor_status.retryCount != 0 and 
              current_status == "connecting"
      # Failed to reconnect and attempting again - keep showing
      should_show = true
    
    @setShouldShowStatus should_show

    return

  return

Template.status_alert.onDestroyed ->
  @clearShowDelayHandle()
  return

Template.status_alert.helpers
  showStatus: ->
    tpl = Template.instance()
    return tpl.should_show_status_rv.get()

  justdoStatusMessage: ->
    return status_messages[Meteor.status().status]