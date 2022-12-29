supported_log_levels = ["DEBUG", "INFO", "WARN", "ERROR", "OFF"]

default_log_level = "WARN"

APP.getEnv (env) ->
  if not env.LOG_LEVEL?
    log_level = default_log_level
  else if env.LOG_LEVEL not in supported_log_levels
    console.warn "[app-logger] unknown log level was set in env var: LOG_LEVEL: '#{env.LOG_LEVEL}', falling back to #{default_log_level} level"
    log_level = default_log_level
  else
    log_level = env.LOG_LEVEL

  console.info "[app-logger] log level: #{log_level}"

  Logger.useDefaults(Logger[log_level])

  APP._logger_ready = true

  APP.emit "logger-ready"