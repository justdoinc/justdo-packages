_.extend JustdoRecaptcha.prototype,
  _setupMethods: ->
    self = @

    Meteor.methods
      justdoRecaptchaVerify: (captcha_input) ->
        check captcha_input, Object # thoroughly checked on @verifyCaptcha

        return self.verifyCaptcha(@connection.clientAddress, captcha_input)

    return

