_.extend JustdoHelpers,
  getUserObjFromMeteorLoginTokenCookie: (request_obj, find_options) ->
    if not (cookies = request_obj?.cookies)?
      # Sometimes the cookies header isn't getting parsed automatically. The following
      # ensures we load the sent http headers.
      if (cookie_header = request_obj?.headers?.cookie)?
        cookies = JustdoHelpers.cookie.parse(cookie_header)

    # request_obj should be Iron Router's server side request object
    if not (login_token = cookies?.meteor_login_token)?
      return undefined

    return Meteor.users.findOne({"services.resume.loginTokens.hashedToken": Accounts._hashLoginToken(login_token)}, find_options)
