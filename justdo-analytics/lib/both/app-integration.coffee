# A temporary APP.justdo_analytics that allow calling APP.justdo_analytics.JA
# before the real one is initiated (init is async). The logs will accumulate
# to a queue, and will be logged once the real APP.justdo_analytics is initiated.
APP.justdo_analytics =
  pre_init_logs_queue: []
  JA: (log, cb) ->
    @pre_init_logs_queue.push([log, cb])

    return

APP.getEnv (env) ->
  if env.JUSTDO_ANALYTICS_ENABLED == "true"
    # Keep a reference to the accumulated pre_init_logs_queue
    # before we overrid, APP.justdo_analytics
    pre_init_logs_queue = APP.justdo_analytics.pre_init_logs_queue

    options = {}

    if Meteor.isServer
      options.storage = env.JUSTDO_ANALYTICS_STORAGE
      options.log_incoming_ddp = env.JUSTDO_ANALYTICS_LOG_INCOMING_DDP is "true"
      options.log_mongo_queries = env.JUSTDO_ANALYTICS_LOG_MONGO_QUERIES is "true"
      options.add_aws_metadata_to_server_env = env.JUSTDO_ANALYTICS_ADD_AWS_METADATA_TO_SERVER_ENV is "true"
      options.devops_public_key = (env.DEVOPS_PUBLIC_KEY or "").replace(/\\n/g, "\n")
      options.log_server_status = env.JUSTDO_ANALYTICS_LOG_SERVER_STATUS is "true"
      options.log_server_status_interval = if not _.isEmpty(env.JUSTDO_ANALYTICS_LOG_SERVER_STATUS_INTERVAL_MS) then parseInt(env.JUSTDO_ANALYTICS_LOG_SERVER_STATUS_INTERVAL_MS) else null
      options.skip_encryption = env.JUSTDO_ANALYTICS_SKIP_ENCRYPTION is "true"

    # If an env variable affect this package load, check its value here
    # remember env vars are Strings
    APP.justdo_analytics = new JustdoAnalytics(options)

    for entry in pre_init_logs_queue
      APP.justdo_analytics.JA.apply(APP.justdo_analytics, entry)
  else
    APP.logger.debug "[justdo-analytics] Disabled"

    # Ignore all attempts to submit analytics & clear pre_init_logs_queue
    APP.justdo_analytics =
      JA: -> return
      logServerRecord: -> return
      logServerRecordEncryptVal: -> return
      logMongoRawConnectionOp: -> return
      JAReportClientSideError: -> return

    if Meteor.isClient
      APP.justdo_analytics.getClientStateValues = (cb) -> JustdoAnalytics.prototype.getClientStateValues(cb) # We make that facility available even when JD Analytics is disabled. Is in use by justdo-user-active-position which is enabled even when analytics is disabled.

    if Meteor.isServer
      APP.justdo_analytics._SSID = JustdoAnalytics.prototype._generateServerSessionId()
      APP.justdo_analytics.getSSID = JustdoAnalytics.prototype.getSSID

  return