errors_types =
  "unknown-path": "Path doesn't exist or doesn't belong to the user"
  "cant-perform-on-root": "This operation can't perform on root path"
  "login-required": "Login required to perform operation"
  "unknown-method-name": "Unknown method name"
  "wrong-type": "Wrong type"
  "grid-method-blocked": "Grid method blocked"
  "operation-blocked": "Operation blocked"
  "operation-cancelled": "Operation cancelled"
  "infinite-loop": "Infinite loop"
  "missing-argument": "Missing argument"
  "wrong-input": "Wrong Input"
  "invalid-option": "Invalid Option"
  "edit-blocked-by-hook": "Edit blocked by hook"
  "unknown-section-manager-type": "Unknown section manager type"
  "forbidden-section-id": "Forbidden section id used"

if Meteor.isClient
  _.extend GridData.prototype,
    # In an effort to encourage standardizing errors types we will issue a warning 
    # if an error of type other than the following will be used
    # The value is the default message
    _errors_types: errors_types

if Meteor.isServer
  _.extend GridDataCom.prototype,
    # In an effort to encourage standardizing errors types we will issue a warning 
    # if an error of type other than the following will be used
    # The value is the default message
    _errors_types: errors_types