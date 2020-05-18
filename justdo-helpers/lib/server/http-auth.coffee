_.extend JustdoHelpers,
  getUserObjFromMeteorLoginTokenCookie: (request_obj) ->
    # request_obj should be Iron Router's server side request object
    if not (login_token = request_obj?.cookies?.meteor_login_token)?
      return undefined

    return Meteor.users.findOne({"services.resume.loginTokens.hashedToken": Accounts._hashLoginToken(login_token)})