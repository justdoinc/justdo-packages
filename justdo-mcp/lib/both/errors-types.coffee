_.extend JustdoMcp.prototype,
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
      "unauthorized": "Authentication required"
      "invalid-token": "Invalid or expired authentication token"
      "invalid-api-key": "Invalid API key"
      "tool-not-found": "The requested tool was not found"
      "invalid-tool-input": "Invalid input parameters for the tool"
      "tool-execution-failed": "Tool execution failed"
      "rate-limit-exceeded": "Rate limit exceeded"