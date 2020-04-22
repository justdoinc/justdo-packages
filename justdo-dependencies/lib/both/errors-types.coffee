_.extend JustdoDependencies.prototype,
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
      "dependency-already-exists": "This dependency already exists",
      "Infinite-dependency-loop": "Infinite dependency loop identified, update reversed..",
      "parent-dependency": "A task can't be dependant on any of its parents, update reversed..",
      "child-dependency": "A task can't be dependant on any of its child-tasks, update reversed..",
      "self-dependency": "Task can't be dependent on itself",
      "dependent-task-not-found": "Task not found."