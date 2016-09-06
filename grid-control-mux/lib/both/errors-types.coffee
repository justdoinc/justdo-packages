_.extend GridControlMux.prototype,
  # In an effort to encourage standardizing errors types we will issue a warning 
  # if an error of type other than the following will be used
  # The value is the default message
  _errors_types:
    "missing-option": "Missing option"
    "id-already-exists": "Provided id already exists"
    "unknown-id": "Provided id doesn't exists"
    "cant-unload-active-tab": "Can't unload active tab"
    "cant-remove-tab": "Can't remove tab"