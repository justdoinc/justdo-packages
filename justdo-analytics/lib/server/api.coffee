crypto = Npm.require("crypto")

ConnectIdentificationObjectSchema = JustdoAnalytics.schemas.ConnectIdentificationObjectSchema

JustdoAnalytics.StorageDrivers = {}

_.extend JustdoAnalytics.prototype,
  _immediateInit: ->
    # Init storage drivers
    @_initStorage()

    @_initServerSession()

    if @options.log_incoming_ddp
      @_initLogIncomingDDP()

    if @options.log_mongo_queries
      @_initLogMongoQueries()

    if @options.log_server_status
      @_initLogServerStatus()

    return

  _deferredInit: ->
    # Defined in methods.coffee
    @_setupMethods()

    # Defined in publications.coffee
    @_setupPublications()

    # Defined in allow-deny.coffee
    @_setupAllowDenyRules()

    # Defined in collections-hooks.coffee
    @_setupCollectionsHooks()

    # Defined in collections-indexes.coffee
    @_ensureIndexesExists()

    # Defined in data-injections.coffee
    @_setupDataInjections()

    return

  currentDdpInvocation: JustdoHelpers.currentDdpInvocation

  currentDdpConnection: JustdoHelpers.currentDdpConnection

  hasDevopsPublicKey: ->
    if not @options.devops_public_key? or _.isEmpty(@options.devops_public_key)
      return false

    return true

  requireDevopsPublicKey: ->
    if not @hasDevopsPublicKey()
      throw @_error "missing-devops-public-key"

    return

  _initServerSession: ->
    if @_server_session_initiated is true
      return

    @_SSID = @_generateServerSessionId()

    if @hasDevopsPublicKey()
      @_local_pass = @_generateLocalPass()
    else
      @_local_pass = null

    server_session =
      SSID: @_SSID

    if @hasDevopsPublicKey()
      @_local_pass = @_generateLocalPass()
      server_session.devops_password_encrypted = @_getEncryptedBase64LocalPass()
    else
      @_local_pass = null
      server_session.devops_password_encrypted = null      

    environment = _.pick process.env, ["ROOT_URL", "APP_VERSION", "NODE_MAX_OLD_SPACE_SIZE"]

    _.extend environment,
      node_version: process.version

    server_session.environment = environment

    complete = =>
      for storage_type, storage_driver of @storage_drivers
        storage_driver._logServerSession(server_session)

      @_server_session_initiated = true

      @logger.debug "Server session initiated"

      return

    if @options.add_aws_metadata_to_server_env is true
      @_addAWSMetaDataToEnvObj environment, ->
        complete()

        return

      return

    complete()

    return

  _generateServerSessionId: ->
    return crypto.randomBytes(15).toString("base64")

  _generateLocalPass: ->
    return crypto.randomBytes(50)

  _getEncryptedBase64LocalPass: ->
    # The local pass, encrypted with the @options.devops_public_key, for safe storage in the
    # session record (only holders of the devops private key, will be able to decrypt and
    # later decrypt the data encrypted with the local pass).

    # To decrypt the result, use:
    #
    # decrypted_pass_buffer = crypto.privateDecrypt(private_key, Buffer.from(devops_encrypted_pass, "base64"))

    return crypto.publicEncrypt(@options.devops_public_key, @_local_pass).toString("base64")

  _encryptWithLocalPass: (string) ->
    if @options.skip_encryption
      return "!ENC! " + string + " !ENC!"

    @requireDevopsPublicKey()

    check string, String

    cipher = crypto.createCipher("aes192", @_local_pass)

    encrypted = cipher.update(string, "utf8", "base64")
    encrypted += cipher.final("base64")

    # To decrypt the result, use:
    #
    # decrypted_pass_buffer below can be obtained from the session record encrypted local pass
    # as described in the comment to @_getEncryptedBase64LocalPass()
    #
    # decipher = crypto.createDecipher("aes192", decrypted_pass_buffer)
    # decrypted = decipher.update(encrypted, "base64", "utf8")
    # decrypted += decipher.final('utf8');
    # console.log(decrypted)

    return encrypted

  _initLogIncomingDDP: ->
    self = @

    @requireDevopsPublicKey()

    Meteor.server.stream_server.server.addListener "connection", (socket) ->
      original = socket._events.data

      socket.on "data", (ddp_message_jsoned) ->
        ddp_message = EJSON.parse(ddp_message_jsoned)

        if ddp_message.msg != "ping" and ddp_message.msg != "pong"
          self.logServerRecord
            cat: "comm"
            act: "ddp-in-enc"
            val: self._encryptWithLocalPass(ddp_message_jsoned)
            UID: socket._meteorSession?.userId
            CID: socket._meteorSession?.id


        return

      return

    @logger.debug "Incoming DDP log initiated"

    return

  _addAWSMetaDataToEnvObj: (environment, cb) ->
    environment.aws = {}

    aws_meta_params = [
      'instance-id'
      'ami-id'
      'ami-launch-index'
      'ami-manifest-path'
      'placement/availability-zone'
      'hostname'
      'instance-action'
      'instance-id'
      'instance-type'
      'local-hostname'
      'local-ipv4'
      'mac'
      'profile'
      'public-hostname'
      'public-ipv4'
    ]

    async.each aws_meta_params, (param, callback) ->
      APP.aws.meta.request '/latest/meta-data/' + param, (err, data) ->
        if err?
          environment.aws[param] = "FAILED!"

          callback()

          return

        environment.aws[param] = data

        callback()

        return

      return
    , (err) ->
      JustdoHelpers.callCb cb

      return

    return

  logMongoRawConnectionOp: (col_name, op, args...) -> return # implemented below, only upon call to _initLogMongoQueries, does nothing if _initLogMongoQueries isn't called.

  _initLogMongoQueries: ->
    jd_self = @

    @requireDevopsPublicKey()

    jd_self.logMongoRawConnectionOp = (col_name, op, args...) ->
      mongo_message_jsoned = EJSON.stringify({col_name, op, args})

      jd_self.logServerRecord {cat: "comm", act: "mongo-out-raw", val: jd_self._encryptWithLocalPass(mongo_message_jsoned)}

      return

    logMeteorMessage = (col_name, op, args) ->
      mongo_message_jsoned = EJSON.stringify({col_name, op, args})

      jd_self.logServerRecord {cat: "comm", act: "mongo-out", val: jd_self._encryptWithLocalPass(mongo_message_jsoned)}

      return

    @logger.debug "Mongo queries log initiated"

    CollectionHooks.additionalCollectionsExtensions = (self, args) ->
      # It seems that in the self._collection, level, it isn't guarenteed that
      # our jd_analytics_skip_logging option won't be cleared (for updates it seems
      # that it doesn't clear, which is great).

      # In addition, as of writing, I am not sure how well it supports
      # findAndModify .

      # What I do know, is that for the second hooking approach, the prototype
      # based, as implemented below, we won't get the ops that are resulted
      # from client side operations performed on the minimongo (allow/deny)
      # _validatedInsert/_validatedUpdate/_validatedRemove , for these I found
      # the collections hooks approach for hooking superior (and working), and
      # so I extended CollectionHooks with the additionalCollectionsExtensions
      # capability for the operations that might come from the client side.

      # Code done in haste (!) and can probably be improved in the future.

      # Daniel C.

      for op in ["insert", "update", "upsert", "remove"]
        do (op) ->
          originalOp = self._collection[op]

          self._collection[op] = (...args) ->
            col_name = self._name

            skip_logging =
              (op in ["update", "upsert"] and args[2]?.jd_analytics_skip_logging)

            if not skip_logging
              logMeteorMessage self._name, op, _.toArray(args)

            return originalOp.apply(self._collection, args)

    for op in ["find", "findOne", "findAndModify"]
      do (op) ->
        originalOp = Mongo._CollectionPrototype[op]

        Mongo._CollectionPrototype[op] = (...args) ->
          col_name = @_name

          skip_logging =
            (op in ["find", "findOne"] and args[1]?.jd_analytics_skip_logging)

          if not skip_logging
            logMeteorMessage @_name, op, _.toArray(args)

          return originalOp.apply(@, args)

    return

  _initLogServerStatus: ->
    os = require("os")

    setInterval =>
      server_status = 
        meteor_open_sessions: _.size(Meteor.server.sessions) - 1 # 1 session is held even when there are no open connections

        "process.version": process.version
        "process.memoryUsage": process.memoryUsage()
        "process.uptime": process.uptime()

        "os.totalmem": os.totalmem()
        "os.freemem": os.freemem()

      server_status_json = EJSON.stringify(server_status)

      @logServerRecord {cat: "server-status", act: "general", val: server_status_json}

      return
    , @options.log_server_status_interval

    return

  isClientConnected: (connection=null) ->
    # We consider the client to be connected if @connect() was called
    # for the current connection, and resulted in the write of
    # the connection.justdo_analytics.client_identification
    # object.

    if not connection?
      connection = @currentDdpConnection()

    if connection.justdo_analytics?.client_identification?
      return true

    return false

  connect: (identification_object) ->
    # console.log "CONNECT REQUEST"

    if @isClientConnected()
      # Already connected, ignore the connection request

      return true

    {cleaned_val} =
      JustdoHelpers.simpleSchemaCleanAndValidate(
        ConnectIdentificationObjectSchema,
        identification_object,
        {self: @, throw_on_error: true}
      )
    identification_object = cleaned_val

    # Perform connection
    connection = @currentDdpConnection()

    if not connection.justdo_analytics?
      connection.justdo_analytics = {}

    connection.justdo_analytics.client_identification = identification_object

    @getASID() # Request a first ASID . We do it here since we want the storages to write the ASID in the time of connection.

    return true

  writeState: (state) ->
    for storage_type, storage_driver of @storage_drivers
      storage_driver._writeState(state)

    return

  getConnectionAnalyticsState: (connection=null) ->
    if not @isClientConnected(connection)
      throw @_error "ja-connect-required"

    if not connection?
      connection = @currentDdpConnection()

    if (analytics_state = connection.justdo_analytics.analytics_state)?
      return analytics_state

    return null

  getASID: (connection=null) ->
    if not @isClientConnected(connection)
      throw @_error "ja-connect-required"

    if not connection?
      connection = @currentDdpConnection()

    env = process.env

    # Since the client is connected, connection.justdo_analytics must exist
    # so no need for connection.justdo_analytics?.analytics_state
    if not (analytics_state = connection.justdo_analytics.analytics_state)?
      # No analytics_state yet, create one
      analytics_state = _.extend {},
        connection.justdo_analytics.client_identification,
        {
          SSID: @_SSID
          CID: connection.id
          ip: connection.clientAddress
          baseURL: env.LANDING_APP_ROOT_URL
          serverBuild: env.APP_VERSION
        }
        # Note we don't set ASID & UID yet, we take care of it for the general case,
        # few lines below

      if (accept_language = connection.httpHeaders["accept-language"])
        analytics_state.acceptLanguage = accept_language

      if _.isEmpty(analytics_state.userAgent) # If the client didn't provide user agent, try get from http header
        if (user_agent = connection.httpHeaders["user-agent"])
          analytics_state.userAgent = user_agent

      connection.justdo_analytics.analytics_state = analytics_state

    if @currentDdpInvocation()?
      # If we don't have DDP invocation, it means that this is a server side
      # log, for which we won't be able to retreive userId using Meteor.userId().
      # We therefore don't try to see whether the userId changed for this log request
      # and simply use the last userId assigned for this JA connection (the last state).
      if analytics_state.UID != Meteor.userId()
        # Set a new ASID every time UID changes
        #
        # userId is the only part of the analytics session that might change
        # during the life of the connection, requiring update for the ASID.
        #
        # Note, we get into this if statement both when we set the analytics_state
        # for the first time for this connection, and when the connected user id
        # changes.

        analytics_state.UID = Meteor.userId()
        analytics_state.ASID = Random.id()

        # Note, analytics_state is a reference to connection.justdo_analytics.analytics_state
        # so no need to set it.

        @writeState(analytics_state)

    return analytics_state.ASID

  logServerRecord: (log_object) ->
    log_object.SSID = @_SSID

    for storage_type, storage_driver of @storage_drivers
      storage_driver._logServerRecord(log_object)

    return

  logServerRecordEncryptVal: (log_object) ->
    # log_object is edited in-place
    if log_object.val?
      log_object.val = @_encryptWithLocalPass(@_encryptWithLocalPass(log_object.val))

    @logServerRecord(log_object)

    return

  logClientSideError: (error_type, val) ->
    check error_type, String
    check val, String

    @logServerRecord({cat: "client-side-error", act: error_type, val: @_encryptWithLocalPass(val)})

    return

  log: (log_object, connection=null) ->
    if not @isClientConnected(connection)
      return {error: "ja-connect-required"}

    # Note, on the server we intentionally don't check the the received log cat/act
    # against the logs registrar.
    #
    # Doing so would make the development by non-web-app developers (mobile devs)
    # much more cumbersome, as they'll need to update the web-dev team on each new
    # event they need and wait for a version to deploy with it.
    #
    # In addition, there might be versions mismatch issues between mobiles and servers
    # (in particular the private cloud servers might have more old version that doesn't
    # have new event more recent mobile apps are logging, and there is no reason not
    # to accept such events).
    log_object = @validateAndSterilizeLog(log_object, false, true) # verify_registered_log=false, see comment above

    log_object.ASID = @getASID(connection)

    # console.log "LOG", log_object # Prefer using the console-sotrage.coffee instead of uncommenting

    # From this point, we can release the blocking, as we want to wait with
    # further logs handling only until we know we got an ASID for this
    # connection.
    @currentDdpInvocation()?.unblock()

    for storage_type, storage_driver of @storage_drivers
      storage_driver._writeLog(log_object, @getConnectionAnalyticsState(connection))

    return {ok: "ok"}

  destroy: ->
    if @destroyed
      @logger.debug "Destroyed already"

      return

    @destroyed = true

    @logger.debug "Destroyed"

    return
