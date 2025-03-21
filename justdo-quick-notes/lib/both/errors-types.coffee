_.extend JustdoQuickNotes.prototype,
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
      "add-task-failed": "Failed to create task from Quick Note"
      "unknown-quick-note": "Unknown Quick Note"
      "task-created-already": "A task was already created from this Quick Note"
      "task-not-found": "Task not found"
      "cannot-undo": "Undo not supported for this task"
