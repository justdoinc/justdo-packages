_.extend JustdoAccounts.prototype,
  _immediateInit: ->
    @login_state_manager = new JustdoLoginState()

    @login_state_tracker = Tracker.autorun =>
      login_state = @login_state_manager.getLoginState()

      login_state_sym = login_state[0]

      if login_state_sym == "logged-in"
        @syncUserTimezone()

    return

  _deferredInit: ->
    @_setupCollectionsHooks()

    return
