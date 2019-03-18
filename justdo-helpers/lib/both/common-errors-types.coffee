_.extend JustdoHelpers,
  common_errors_types:
    # The following errors types extends the @_errors_types
    # object of all the packages that uses justdo-package-skeleton
    # version >= 0.0.4
    #
    # Make use of them!
    "fatal": "Fatal issue"
    "not-supported": "Not supported"
    "invalid-options": "Invalid options" # used in /both/simple-schema.coffee
    "invalid-argument": "Invalid argument"
    "missing-argument": "Missing argument"
    "login-required": "This operation requires login"
    "unknown-user": "Unknown user"