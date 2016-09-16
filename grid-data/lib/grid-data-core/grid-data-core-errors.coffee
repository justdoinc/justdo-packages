_.extend GridDataCore.prototype,
  # In an effort to encourage standardizing errors types we will issue a warning 
  # if an error of type other than the following will be used
  # The value is the default message
  _errors_types:
    "required-option-missing": "Required option missing"
    "schemaless-collection": "GridData called for a collection with no simpleSchema definition"