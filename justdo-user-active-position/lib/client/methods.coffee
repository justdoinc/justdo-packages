_.extend JustdoUserActivePosition.prototype,
  logPos: (pos, cb) ->
    base_pos =
      DID: @jd_analytics_client_state.DID
      SID: @jd_analytics_client_state.SID
      page: JustdoHelpers.currentPageName()

    extended_pos = _.extend base_pos, pos
    
    # "time" is for client-side only. The actual "time" stored in db is dictated by schema's autovalue.
    delete extended_pos.time

    # If the user is not showing their active position, we mark the pos as private
    # so that it doesn't appear in the active positions grid.
    if not @isCurrentUserShowingActivePosition()
      extended_pos.private = true

    Meteor.call("logPos", extended_pos, cb)
    
    return

  hideUserActivePosition: (cb) ->
    # When a user hides their active position, we fire an "EXIT" event immediately
    # so that it removes the active position from the UI immediately.
    @logPos({page: "EXIT"})
    Meteor.call("hideUserActivePosition", cb)

  showUserActivePosition: (cb) ->
    Meteor.call("showUserActivePosition", cb)

