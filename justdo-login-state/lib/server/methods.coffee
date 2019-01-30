_.extend JustdoLoginState.prototype,
  _setupMethods: ->
    login_state_object = @

    Meteor.methods
      getUserByVerificationToken: (verification_token) ->
        check(verification_token, String)

        return login_state_object.getUserByVerificationToken verification_token, @userId

      getUserByResetToken: (reset_token) ->
        check(reset_token, String)

        return login_state_object.getUserByResetToken reset_token, @userId