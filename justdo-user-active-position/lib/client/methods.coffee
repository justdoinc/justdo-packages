_.extend JustdoUserActivePosition.prototype,
  logPos: (pos, cb) ->
    base_pos =
      DID: @jd_analytics_client_state.DID
      SID: @jd_analytics_client_state.SID
      page: JustdoHelpers.currentPageName()

    extended_pos = _.extend base_pos, pos
    
    # "time" is for client-side only. The actual "time" stored in db is dictated by schema's autovalue.
    delete extended_pos.time

    Meteor.call("logPos", extended_pos, cb)
    
    return

  hideUserActivePosition: (cb) ->
    Meteor.call("hideUserActivePosition", cb)

  showUserActivePosition: (cb) ->
    Meteor.call("showUserActivePosition", cb)

