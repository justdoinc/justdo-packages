_.extend JustdoAccounts.prototype,
  # In an effort to encourage standardizing errors types we will issue a warning 
  # if an error of type other than the following will be used
  # The value is the default message
  _errors_types:
    "login-required": "This operation requires login"
    "login-already": "This operation can't be performed by logged-in users"
    "missing-argument": "Missing Argument"
    "plain-text-password-on-wire-forbidden": "Plain text password on wire forbidden"
    "password-must-be-set-for-client-create-user": "Password must be set for client create user"
    "username-not-supported": "Username not supported"
    "profile-missing": "profile option is required in order to create a new user"
    "invalid-email": "Invalid email provided"
    "unknown-user": "Unknown user"
    "unknown-legal-doc": "Unknown legal doc"
    "no-email-associated-with-user": "No email is associated with this user"
    "user-already-exists": "User already exists"
    "user-already-verified": "User already verified"
    "expected-string": "Expected value to be string"
    "permission-denied": "Permission denied"
    "already-promoter": "User has already registered as a promoter"