setupUserLoginResumeTokenTtl = (env) ->
  user_login_resume_token_ttl_ms = env.USER_LOGIN_RESUME_TOKEN_TTL_MS

  if user_login_resume_token_ttl_ms?
    if not _.isString(user_login_resume_token_ttl_ms)
      throw new Error("Invalid value to env var USER_LOGIN_RESUME_TOKEN_TTL_MS")

    user_login_resume_token_ttl_ms = user_login_resume_token_ttl_ms.trim()

    if user_login_resume_token_ttl_ms == "0" or _.isEmpty(user_login_resume_token_ttl_ms)
      user_login_resume_token_ttl_ms = undefined
    else
      user_login_resume_token_ttl_ms = parseInt(user_login_resume_token_ttl_ms, 10)

      if _.isNaN(user_login_resume_token_ttl_ms) or not _.isNumber(user_login_resume_token_ttl_ms)
        throw new Error("Invalid value provided to env var: USER_LOGIN_RESUME_TOKEN_TTL_MS: #{env.USER_LOGIN_RESUME_TOKEN_TTL_MS}")

  if user_login_resume_token_ttl_ms?
    console.log "USER_LOGIN_RESUME_TOKEN_TTL_MS=#{user_login_resume_token_ttl_ms} (#{user_login_resume_token_ttl_ms / (1000 * 60 * 60 * 24)} days) Found, setting up expiration procedure"
    Accounts.config({loginExpirationInDays: user_login_resume_token_ttl_ms / (1000 * 60 * 60 * 24)})

    if Meteor.isClient
      # When the session timesout, before the server actually clears the resume token
      # from the DB the user can actually still use the connection formed.
      # That's an undesired situation for the reason that if a company wants a short timeout,
      # e.g 10mins, the clearout might add significant amount of minutes to session life.
      # therefore, we also actively ensures in an interval that the session is still alive
      Meteor.setInterval ->
        if JustdoHelpers.datesMsDiff(new Date(Accounts._storedLoginTokenExpires())) < 0
          JustdoHelpers.showSessionTimedoutMessageAndLogout()
        return
      , 5000

  return

APP.executeAfterAppLibCode ->
  if Meteor.isServer
    setupUserLoginResumeTokenTtl(process.env)

  if Meteor.isClient
    APP.getEnv (env) ->
      setupUserLoginResumeTokenTtl(env)
      return

  return