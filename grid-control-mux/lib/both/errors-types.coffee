_.extend GridControlMux.prototype,
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
      "missing-option": "Missing option"
      "id-already-exists": "Provided id already exists"
      "unknown-id": "Provided id doesn't exists"
      "cant-unload-active-tab": "Can't unload active tab"
      "cant-remove-tab": "Can't remove tab"