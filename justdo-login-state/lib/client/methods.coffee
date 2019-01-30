_.extend JustdoLoginState.prototype,
  getUserByVerificationToken: (verification_token, cb) ->
    Meteor.call "getUserByVerificationToken", verification_token, cb

  getUserByResetToken: (reset_token, cb) ->
    Meteor.call "getUserByResetToken", reset_token, cb
