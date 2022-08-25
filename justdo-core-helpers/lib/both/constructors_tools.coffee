_.extend JustdoCoreHelpers,
  constructor_error: (type, message, details) ->
    # constructor_error(type[, message, details])
    # constructor_error(type[, message]) <- If second arg is string will be regarded as message
    # constructor_error(type[, details]) <- If second arg is obj will be regarded as details
    #
    # Takes care of producing Meteor.Error, proper console log messages (with
    # Logger), and help manage errors types.
    #
    # returns Meteor.Error obj.
    #
    # Usage in your constructor's prototype add:
    #
    # _.extend X.prototype
    #   logger: Needs to be a Logger object
    #
    #   _error: JustdoCoreHelpers.constructor_error
    #
    #   _errors_types:
    #     # In an effort to encourage standardizing errors types we will issue a warning 
    #     # if an error of type other than the following will be used
    #     # The value is the default message
    #     "dashed-error-type": "Default Message"
    #
    # Then, from within your constructors methods simply call:
    #
    #   @error(type, message, details)
    #
    # Arguments:
    #
    #   type: a type corresponding to those specified in _errors_types
    #   message: a string for error message, will be logged and passed to
    #   the generated Meteor.Error
    #   details: details object, will be logged and passed to the generated
    #   Meteor.Error

    if _.isObject message
      details = message
      message = undefined 

    if not(type of @_errors_types)
      @logger.warn("Unknown error type: #{type}")
    else
      # Use default if type is known and no message provided
      if not message? or _.isEmpty(message)
        message = @_errors_types[type]

    log_message = "[#{type}] #{message}"
    if details?
      try
        log_message += " #{JSON.stringify details}"
      catch e
        # We'll fail to stringify if details is a complex object, in such a case we just avoid adding it to the log_message.
        undefined

    @logger.error(log_message)

    return new Meteor.Error(type, message, details)

  performIfPlguinInstalledAndConditionIsMet: (project_id, options) ->
    if not options.is_complex_condition? or options.is_complex_condition is false
      if options.condition() is true
        if APP.projects.isPluginInstalledOnProjectId(this.constructor.project_custom_feature_id, project_id)
          return options.operation()
    else
      if APP.projects.isPluginInstalledOnProjectId(this.constructor.project_custom_feature_id, project_id)
        if options.condition() is true
          return options.operation()

    return
