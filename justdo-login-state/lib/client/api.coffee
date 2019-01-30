login_state_dependency = new Tracker.Dependency()
login_state = null

_.extend JustdoLoginState.prototype,
  getLoginState: ->
    # Reactive resource
    #
    # States are:
    #
    # ["loading"] - state isn't determined yet
    # ["logged-in", user, initial_state]
    # ["logged-out", initial_state]
    # The following states will always be initial, so no need to
    # pass initial_state
    # ["email-verification", token, user, done]
    # ["email-verification-expired"]
    # ["reset-password", token, user, done]
    # ["reset-password-expired"]
    # ["enrollment", token, user, done]
    # ["enrollment-expired"]

    self = @

    login_state_dependency.depend()

    # The manager is actually set only once, after it is set
    # we just return the login_state
    if login_state?
      return login_state

    # initial_state indicates whether the current state is the initial state
    #
    # loading is not considered initial, only the first non-loading state
    #
    # Check the states map above to see which states includes information on
    # whether or not they are initial.
    #
    # null means not yet found, true means current is the initial, false means not initial
    initial_state = null 
    setUserState = (new_state) ->
      if new_state[0] == login_state[0]
        # Don't trigger reactivity if state didn't really change
        return

      login_state = new_state

      login_state_sym = login_state[0]

      if initial_state is null
        # Note that we don't need to worry that initial_state is
        # loading as the if in the above will clear it out.
        # The initial loading state is set outside of this function
        initial_state = true
      else if initial_state is true
        initial_state = false

      # Add the initial_state value to the states that
      # exposes this information
      if login_state_sym in ["logged-in", "logged-out"]
        login_state.push initial_state

      login_state_dependency.changed()

    # inital state, no need to call login_state_dependency.changed()
    login_state = ["loading"]

    # auto_login_disabled will be true if auto login disabled
    # due to: verification, and password reset attempt.
    # verification, and password reset attempts put login in a suspended
    # state to wait for the interaction to finish, so in these cases
    # we need to wait for the process to finish before we
    # initLoginStateComputation
    auto_login_disabled = false

    getLoginTokenFromStorage = -> localStorage.getItem "Meteor.loginToken"

    loadInjectedLoginToken = (done_cb) ->
      # Look for InjectData's 'login-token' to determine whether a user
      # session token received by the request and got injected.
      # See server/data-injections.coffee for more details.
      #
      # If such a session token received set it up as the current user
      # session (override existing session).
      # Otherwise, do nothing.
      #
      # Upon completion of loadInjectedLoginToken procedures done_cb
      # will be called (InjectData.getData is async, so this func is
      # async also).

      InjectData.getData "login-token", (token) ->
        current_token = getLoginTokenFromStorage()

        if not token? or token == current_token 
          # If no token injected, or existing token provided,
          # nothing to do
          done_cb?()

          return

        # If a new token received, begin from making sure
        # we are logged out, to avoid wrongly recognizing
        # the logging in of the existing session as the
        # logging in of the new user (see autorun below)
        self.logger.debug "New login session detected: processing; logging out existing sessions (if any)"
        APP.justdo_analytics.JA({cat: "core", act: "post-sign-in-redirect-processing"})

        Meteor.logout ->
          self.logger.debug "New login session detected: installing new session token"

          # Set the new login token into the local storage
          self.installLoginToken token

          Tracker.autorun (c) ->
            # Wait for Meteor to load the new loginToken
            # and attempt logging-in with it

            callDoneCb = ->
              # The proper way to call done_cb from within this
              # computation
              c.stop()
              Tracker.nonreactive ->
                # Tracker.nonreactive is here since we don't want reactive processes
                # in done_cb to be affected by this computation stopping.
                # Tracker.nonreactive server as a seperation of reactive contexts
                # in that case and not as an actual nonreactive
                done_cb()

            if Meteor.loggingIn() or Meteor.userId()?
              self.logger.debug("New login session detected: loaded successfully")

              APP.justdo_analytics.JA({cat: "core", act: "post-sign-in-redirect-completed"})

              callDoneCb()
            else if not getLoginTokenFromStorage()?
              # This case will occur if on the next invalidation of this
              # computation, the storage will be clear from the session
              # token we put in it. i.e. the provided session was incorrect.
              #
              # This case will run only if Meteor.loggingIn() will be false
              # already when the computation will run again.
              #
              # Note: In case Meteor.loggingIn() is true and a wrong session token
              # provided, callDoneCb will be called anyway, see prev condition
              # this condition just serve to recognize rerun, and distinguish it
              # from first run
              self.logger.debug("New login session detected: Meteor rejected provided login session")

              callDoneCb()
            else
              self.logger.debug("New login session detected: Installed, waiting for meteor to load new login session")

    initLoginStateComputation = ->
      Tracker.autorun (c) ->
        if Meteor.loggingIn()
          setUserState(["loading"])
        else
          if Meteor.userId()?
            # If we have userId, we keep the loading state until
            # user obj is ready
            if not (user = Meteor.user())?
              setUserState(["loading"])
            else
              # If Meteor.user is not null, we got a user
              setUserState(["logged-in", user])
          else
            # If Meteor.userId() is null, no user, no chance to find one
            setUserState(["logged-out"])

      self.logger.debug("Main login-state computation running")

    Tracker.nonreactive ->
      # This Tracker.nonreactive breaks the link from any enclosing
      # computation to the computation we are going to initiate,
      # that way, the following computation will keep running even
      # if the first computation that called getLoginState got stopped
      # so the following will keep tracking the state for future calls
      # to getLoginState

      # Note that since the email verification and password reset hooks
      # (Accounts.onEmailVerificationLink) are also triggered on Meteor.startup
      # and since their package loads first, we can be sure the following
      # will run after auto_login_disabled got determined
      Meteor.startup ->
        if not auto_login_disabled
          # Note that if auto_login_disabled is true,
          # later when we call the login, we doesn't
          # call first loadInjectedLoginToken() as
          # the combination of auto login blocking request
          # and a login session request can't happen.
          loadInjectedLoginToken ->
            initLoginStateComputation()

    accounts_hooks_done_wrapper = (done) ->
      wrapped_done = _.wrap done, (done) ->
        initLoginStateComputation()

        done()

      return wrapped_done

    hooks_defs = [
      [Accounts.onEmailVerificationLink, "email-verification"]
      [Accounts.onResetPasswordLink, "reset-password"]
      [Accounts.onEnrollmentLink, "enrollment"]
    ]

    for hook_def in hooks_defs
      [hook, hook_sym] = hook_def

      do (hook, hook_sym) =>
        hook.call Accounts, (token, done) =>
          auto_login_disabled = true

          wrapped_done = accounts_hooks_done_wrapper(done)

          userFetcherHandler = (err, user_obj) =>
            if err?
              setUserState([hook_sym + "-expired", err])

              # In the case of failute, we call the wrapped_done
              # ourself, once the time set in @options.expired_token_state_delay
              # passed
              setTimeout ->
                wrapped_done()
              , @options.expired_token_state_delay

              return

            setUserState([hook_sym, token, user_obj, wrapped_done])

            return

          if hook_sym == "email-verification"
            @getUserByVerificationToken token, userFetcherHandler
          else
            @getUserByResetToken token, userFetcherHandler # enrollment use reset too

          return

    return login_state

  isInitialLoginState: ->
    # Returns true if current state is the initial login state
    # false otherwise
    #
    # Important: loading is not considered initial, only the first non-loading state
    #
    # Reactive resource
    current_login_state = @getLoginState()

    login_state_sym = current_login_state[0]

    if login_state_sym == "loading"
      return false
    else if login_state_sym in ["logged-in", "logged-out"]
      return _.last current_login_state
    else
      # at the moment all the other sym can happen only on init 
      return true

  loginStateIs: ->
    # Gets an arbitrary list of states ids and return true
    # if any of them is the current state
    #
    # Reactive resource

    args = _.toArray arguments

    current_login_state = @getLoginState()[0]

    for state in args
      if state == current_login_state
        return true

    return false

  getInitialUserStateReadyReactiveVar: ->
    # Returns a reactive var that turns to true when initial logging
    # in is completed to the point where we can get the user info
    # from Meteor.user(), or when we are sure there's no logged-in
    # user
    #
    # It's recommended to connect the output var to
    #
    #   APP.initial_user_state_ready = JustdoLoginState.getInitialUserStateReadyReactiveVar()
    #
    # so all part of the app can use the same user state recognition
    # reactive var
    self = @

    initial_user_state_ready = new ReactiveVar(false)

    Tracker.autorun (c) ->
      if self.getLoginState()[0] != "loading"
        initial_user_state_ready.set(true)

        c.stop()

    return initial_user_state_ready

  installLoginToken: (token) ->
    localStorage.setItem "Meteor.loginToken", token

    return