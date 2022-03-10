_.extend TasksFileManager.prototype,
  # In an effort to encourage standard errors types we will
  # issue a warning if an error of type other than the following
  # will be used.
  #
  # Errors types should be hyphen-separated
  # The value is the default message
  #
  # Throw errors by: throw @_error("error-type", "Custom message")
  _errors_types:
    _.extend {}, JustdoHelpers.common_errors_types,
      "login-required": "Login required"
      "task-not-found": "Task not found"
      "file-not-found": "File not found"
      "file-url-invalid": "File url is not a filestack url"
      "api-key-required": "Filestack API key required"
      "api-secret-required": "Filestack API secret required"
      "api-version-not-supported": "API version not supported"