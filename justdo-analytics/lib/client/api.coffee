# TODO, make an option
max_JA_retries = 2
storage_key = "JA.ID" # WIll be set on localStorage for DID, sessionStorage for SID

_.extend JustdoAnalytics.prototype,
  _immediateInit: ->
    # We set @blockJA to true if we determine analytics is blocked
    # for the environment.
    #
    # Note, that after a server restart that doesn't involve changes
    # to the frontend the client won't refresh. Still, it is possible
    # that analytics got disabled or enabled in the server. Therefore,
    # everytime we recognize reconnection we change @blockJA back to
    # false and attempt to connect (after which, if we recognize JA
    # is blocked we'll set it to true).
    @blockJA = false

    # The following takes care of calling @connect() every time
    # a new Meteor connection is established.
    #
    # The connect process, in which we identify the client, is necessary
    # for the server to accept logs from that client and need to be done
    # for every new connection.
    last_status = null
    @reconnectTracker = Tracker.autorun =>
      cur_status = Meteor.status().status

      if last_status != cur_status and cur_status == "connected"
        @logger.debug "Server re/connected, connect to JA"

        # When the server is reconnected, set @blockJA to false, for case
        # analytics got enabled during the time we've been offline.
        #
        # See comment above where @blockJA is first initialized.
        @blockJA = false

        @connect()

      last_status = cur_status

      return

    return

  _deferredInit: ->
    return

  _guessPID: ->
    res = /\/p\/([^?#\/]+)/.exec(window.location.href)
    
    if res?
      return res[1]

    return undefined

  getClientStateValues: (cb) ->
    # Returns to cb the state values object as first param.
    self = @

    APP.getEnv (env) =>
      InjectData.getData "justdo-analytics", (token) ->
        state_vals =
          appVersion: env.APP_VERSION or ""

        state_vals.CType = JustdoHelpers.getClientType(env)

        # Set DID and SID
        if token?
          # Check if attempt is made to forcefully set DID/SID
          # Note we do some validations to the token on the server
          # for example, we know for sure we can count on | to exist
          # along with 2 17 chars strings 
          [DID, SID] = token.split("|")

          # Note, even if there's DID/SID, we simply ignore them 
          if localStorage.getItem(storage_key) != DID
            localStorage.setItem(storage_key, DID)

            self.logger.debug "DID set request processed"

          if sessionStorage.getItem(storage_key) != SID
            sessionStorage.setItem(storage_key, SID)

            self.logger.debug "SID set request processed"

          state_vals.DID = DID
          state_vals.SID = SID
        else
          # Get SID/SID from storages generate new if storages don't have them.
          for val_name, storage_driver of {DID: localStorage, SID: sessionStorage}
            val = storage_driver.getItem(storage_key)
            if not val? or val.length != 17
              val = Random.id()

              storage_driver.setItem(storage_key, val)

            state_vals[val_name] = val

        cb(state_vals)

    return

  _ongoingActiveConnectAttempt: false
  _ongoingActiveConnectAttemptCbs: null
  connect: (cb) ->
    if @_ongoingActiveConnectAttempt
      # During the time we are not connected, all calls to @JA
      # will result in connection attempt, we want to avoid
      # calling the JAConnect method when an active connection
      # attempt is already on going, and instead just wait for
      # that connection attempt to complete. 
      @logger.debug "JA connection attempt is already ongoing, batching connect request"

      @_ongoingActiveConnectAttemptCbs.push(cb)

      return

    @_ongoingActiveConnectAttempt = true
    @_ongoingActiveConnectAttemptCbs = [cb]
    @getClientStateValues (state_vals) =>
      Meteor.call "JAConnect", state_vals, (err) =>
        if not (error = err?.error)?
          @logger.debug "connect: JA Connected successfully"
        else
          if error == 404
            @logger.debug "connect: JA is not enabled for this environment, block JA."

            @blockJA = true
          else 
            @logger.warn "connect: JA connect attempt failed", err

        # @logger.debug "connect: call #{@_ongoingActiveConnectAttemptCbs.length} connection waiting CBs"
        for _cb in @_ongoingActiveConnectAttemptCbs
          JustdoHelpers.callCb _cb, err

        @_ongoingActiveConnectAttempt = false
        @_ongoingActiveConnectAttemptCbs = null

        return

      return

  JA: (log, cb, attempt=0) ->
    # cb will be called with an error object as its first parameter.
    # the returned error object might not be the common Meteor
    # error object but it is promised to have at least an "error"
    # property.

    if @blockJA
      @logger.debug "JA is blocked, ignoring log request"

      return

    if attempt >= max_JA_retries
      # Give up after 2nd attempt (prevent any chance for infinite loop here)

      @logger.debug "JA failed. Attempts count: #{attempt}"

      return

    log = @validateAndSterilizeLog(log)

    if attempt > 0
      @logger.debug "JA retry. Attempt count: #{attempt}"    

    # If the provided log doesn't have the pid prop
    # and we can guess the PID.
    if not log.pid? and (pid = @_guessPID())?
      log.pid = pid

    Meteor.call "JA", log, (ddp_err, result) =>
      if ddp_err?
        JustdoHelpers.callCb(cb, ddp_err)

        return

      if not (error = result.error)?
        # @logger.debug "JA logged successfully: #{log}. (attempt: #{attempt})"

        JustdoHelpers.callCb(cb, undefined, result)

        return

      # If the result object itself has an error object,
      # see whether there's a place for trying again.
      if error == "ja-connect-required"
        @logger.debug "JA reconnect is required. Reconnect and try again"

        @connect (connect_err) =>
          if connect_err?
            @logger.debug "JA reconnect failed. JA log lost."

            # If JAConnedct failed, give up.
            JustdoHelpers.callCb(cb, err)

            return

          @logger.debug "JA reconnected. Try log message again."

          # Reconnect succeeded, retry
          @JA(log, cb, attempt += 1)

          return

        return
      else
        # In any other case, we don't try again.

        @logger.debug "JA failed. JA log lost."

        # If connect failed, give up.
        JustdoHelpers.callCb(cb, err)

        return

    return

  JAReportClientSideError: (error_type, val) ->
    if not _.isString val
      val = JSON.stringify(val)

    val = JSON.stringify({val: val, trace: Error().stack})

    Meteor.call "JAReportClientSideError", error_type, val

    return

  destroy: ->
    if @destroyed
      @logger.debug "Destroyed already"

      return

    @destroyed = true

    @reconnectTracker?.stop()

    @logger.debug "Destroyed"

    return