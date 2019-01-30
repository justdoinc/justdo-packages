_.extend JustdoAnalyticsCoreLogs.prototype,
  setupEvents: ->
    @setupTabLoadDetector()
    @setupMigrationReloadDetector()
    @setupLoginStateDetector()
    @setup404Detector()
    @loadRouteDetector()

    return

  setupTabLoadDetector: ->
    tab_load_val = {}

    if document.referrer? and not _.isEmpty(document.referrer)
      tab_load_val.referrer = document.referrer

    if (href = document.location.href)?
      sensative_urls_comp = ["reset-password", "verify-email", "enroll-account"]
      sensative_urls_regexp = new RegExp("(/(:?#{sensative_urls_comp.join("|")})/)(\\S*)")

      href = href.replace(sensative_urls_regexp, "$1")

      tab_load_val.href = href

    @JA({act: "tab-load", val: JSON.stringify(tab_load_val)})

  setupMigrationReloadDetector: ->
    # Resources to learn more about what's done here:
    # https://github.com/meteor/meteor/blob/87681c8f166641c6c3e34958032a5a070aa2d11a/packages/autoupdate/autoupdate_client.js
    # https://github.com/meteor/meteor/blob/87681c8f166641c6c3e34958032a5a070aa2d11a/packages/reload/reload.js
    # https://github.com/meteor/meteor/blob/800f07349bddbfbf748888b1107cb5dfab81cdc7/packages/reactive-dict/migration.js#L36
    Package.reload.Reload._onMigrate "log-migrgration", =>
      @JA({act: "migration-reload"})

      return [true, {}]

    return

  setupLoginStateDetector: ->
    self = @

    last_non_loading_state = null
    Tracker.autorun ->
      login_state = APP.login_state.getLoginState()
      login_state_sym = login_state[0]

      if login_state_sym == last_non_loading_state
        # We had a sequence of sym_x, loading, sym_x - we ignore this case

        return

      if login_state_sym != "loading"
        last_non_loading_state = login_state_sym

      if login_state_sym == "loading"
        return # We report nothing for this state
      else if login_state_sym == "logged-in"
        if not APP.login_state.isInitialLoginState() # If initial, it isn't a sign-in, user hit the page as signed-in already and didn't sign-in now
          self.JA({act: "sign-in"})
      else if login_state_sym == "logged-out"
        if not APP.login_state.isInitialLoginState() # If initial, it isn't a sign-in, user hit the page as signed-in already and didn't sign-in now
          self.JA({act: "sign-out"})
      else
        val = login_state_sym

        if login_state_sym in ["email-verification", "reset-password", "enrollment"]
          val += "|#{login_state?[2]?._id}"

        self.JA({act: "special-user-state", val: val})


      return

  setup404Detector: ->
    self = @

    Tracker.autorun ->
      if Router.current()?._handled is false
        self.JA({act: "404-route", val: window.location.href})

      return

    return

  loadRouteDetector: ->
    self = @

    Tracker.autorun ->
      router = Router.current()

      page_name = JustdoHelpers.currentPageName()

      if page_name?
        # We defer the call to JA to the next tick, since at this
        # point window.location.href isn't set yet to the new location
        # which JustdoAnalytics rely on to extract PID on the web-app
        # (and potentially other params in future)
        Meteor.defer ->
          self.JA({act: "load-route", val: "#{page_name}|#{router.url}"})

      return

    return

  destroy: ->
    if @destroyed
      @logger.debug "Destroyed already"

      return

    @destroyed = true

    @logger.debug "Destroyed"

    return