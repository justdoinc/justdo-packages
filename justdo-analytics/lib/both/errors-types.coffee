_.extend JustdoAnalytics.prototype,
  # In an effort to encourage standard errors types we will
  # issue a warning if an error of type other than the following
  # will be used.
  #
  # Errors types should be hyphen-separated
  # The value is the default message
  #
  # Throw errors by: throw @_error("error-type", "Custom message")
  #
  # Note that there's a list of common_errors_types that are used
  # as the base for all the packages based on
  # justdo-package-skeleton >= 0.0.4
  _errors_types:
    _.extend {}, JustdoHelpers.common_errors_types,
      "ja-connect-required": "JA connect required"
      "unknown-stoarge-type": "Unknown stoarge type"
      "unknown-log-type": "Unknown log type"
      "missing-devops-public-key": "You must provide @options.devops_public_key (or disable options that need it such as: log_incoming_ddp/log_mongo_queries)"