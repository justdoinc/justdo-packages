_.extend Projects.prototype,
  # In an effort to encourage standardizing the app's errors types we will issue a warning 
  # if an error of type other than the following will be used
  # The value is the default message
  #
  # Note that there's a list of common_errors_types that are used
  # as the base for all the packages based on
  # justdo-package-skeleton >= 0.0.4
  _errors_types:
    _.extend {}, JustdoHelpers.common_errors_types,
      "validation-error": "Validation Error"
      "unknown-project": "Unknown Project"
      "invalid-email": "Invalid email provided"
      "invalid-id": "Invalid id"
      "login-already": "This operation can't be performed by logged-in users"
      "admin-permission-required": "This operation requires you to have admin permission on this JustDo"
      "user-not-exists": "Couldn't find a user with the provided details"
      "member-already-exists": "Member already exists in this JustDo"
      "unknown-members": "Members don't belong to JustDo"
      "cant-remove-last-project-admin": "Project cannot be left without registered admins"
      "unknown-mode": "Unknown Mode"
      "env-var-missing": "Required environment variable isn't set"
      "initiation-performed-already": "Initiation performed already"
      "cant-find-states-definitions-in-schema": "Can't find states definitions in schema"
      "illegal-reject-message-setting-attempt": "Illegal attempt to set reject ownership message"
      "permission-denied": "Permission Denied"
      "not-task-member": "User isn't task member"
      "memebr-already-enrolled": "Member already enrolled" 
      "forbidden": "Forbidden"
