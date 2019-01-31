# Note, StorageDriverPrototype is not added as part of JustdoAnalytics prototype.

JustdoAnalytics.StorageDriverPrototype = ->
  @pre_init_states_queue = []
  @pre_init_logs_queue = []
  @pre_init_server_session_queue = []
  @pre_init_server_records_queue = []

  @is_init = false

  done = =>
    @is_init = true

    for server_session in @pre_init_server_session_queue
      @logServerSession(server_session)

    for server_record in @pre_init_server_records_queue
      @logServerRecord(server_record)

    for state in @pre_init_states_queue
      @writeState(state)

    for log_args in @pre_init_logs_queue
      @writeLog.apply(@log, log_args)

    return

  fail = =>
    # Clear pre-init queues
    @pre_init_states_queue = []
    @pre_init_logs_queue = []

    # Block all future attempt to write to this storage
    @_writeState = -> return
    @_writeLog = -> return
    @_logServerSession = -> return
    @_logServerRecord = -> return


    APP.logger.error("[justdo-analytics] analytics-storage-init-failed", "Analytics Storage Init Failed")

    return

  @init(done, fail)

  return @

_.extend JustdoAnalytics.StorageDriverPrototype.prototype,
  _writeState: (state) ->
    # console.log "_writeState", state
    if @is_init
      @writeState(state)
    else
      @pre_init_states_queue.push(state)

    return

  _writeLog: (log, analytics_state) ->
    # console.log "_writeLog", log
    if @is_init
      @writeLog(log, analytics_state)
    else
      @pre_init_logs_queue.push([log, analytics_state])

    return

  _logServerSession: (server_session) ->
    # console.log "_logServerSession", log
    if @is_init
      @logServerSession(server_session)
    else
      @pre_init_server_session_queue.push(server_session)

    return

  _logServerRecord: (log) ->
    # console.log "_logServerRecord", log
    if @is_init
      @logServerRecord(log)
    else
      @pre_init_server_records_queue.push(log)

    return

  init: (done, failed) -> return # To be implemented by inheritors

  writeState: (state) -> return # To be implemented by inheritors

  writeLog: (log) -> return # To be implemented by inheritors
