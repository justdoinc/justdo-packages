_.extend GridControl.prototype,
  # In an effort to encourage standardizing errors types we will issue a warning 
  # if an error of type other than the following will be used
  # The value is the default message
  _errors_types:
    "grid-control-schema-error": "Schema error"
    "grid-control-invalid-view": "Invalid view"
    "edit-failed": "Edit failed"
    "unknown-filter-type": "Unknown filter type"
    "unfulfilled-prereq": "Grid operation called with unfulfilled prerequisites"
    "wrong-argument": "Wrong argument provided"