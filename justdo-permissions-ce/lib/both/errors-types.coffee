_.extend JustdoPermissions.prototype,
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
      "insufficient-permission": "You don't have the necessary permission to perform this action"
      "unknown-permission-condition": "Unknown permission condition"
      "missing-permission-condition-required-field": "Missing permission condition required field"
      "unknown-task": "Unknown task"