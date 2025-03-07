_.extend JustdoAccounts.prototype,
  _immediateInit: ->
    @login_state_manager = new JustdoLoginState()

    @login_state_tracker = Tracker.autorun =>
      login_state = @login_state_manager.getLoginState()

      login_state_sym = login_state[0]

      if login_state_sym == "logged-in"
        @syncUserTimezone()

    @pending_jd_creation_request = null
    @_setupEventHooks()

    return

  _deferredInit: ->
    @_setupCollectionsHooks()

    return
