_.extend JustdoLoginState.prototype,
  getUserByVerificationToken: (verification_token) ->
    user = Meteor.users.findOne
      "services.email.verificationTokens.token": verification_token

    if not user?
      throw @_error("token-expired")

    return user

  getUserByResetToken: (reset_token) ->
    user = Meteor.users.findOne
      "services.password.reset.token": reset_token

    if not user?
      throw @_error("token-expired")

    return user