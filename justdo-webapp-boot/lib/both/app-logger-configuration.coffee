APP.getEnv (env) ->
  if Meteor.isServer
    # On the server we want as much information as possible to be logged
    log_level = Logger.DEBUG
  else
    if env.ENV in ["dev", "development"]
      log_level = Logger.DEBUG
    else if env.ENV in ["stg", "staging"]
      log_level = Logger.INFO
    else if env.ENV in ["prod", "production"]
      log_level = Logger.WARN
    else
      # Will happen when we run $ meteor; command directly without setting env vars
      log_level = Logger.DEBUG

  Logger.useDefaults(log_level)

  APP._logger_ready = true

  APP.emit "logger-ready"