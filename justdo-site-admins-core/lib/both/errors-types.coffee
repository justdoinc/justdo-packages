_.extend JustdoSiteAdmins.prototype,
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
      "site-admin-required": "Site admin required"
      "unknown-_module-id": "Unknown _module id" # _ added before of the word _module cause babel transpiler breaks the build if that word appears anywhere, even in a comment
