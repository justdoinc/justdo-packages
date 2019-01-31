_.extend JustdoHelpers,
  getClientType: (env) ->
    # We get env as an argument to avoid making this func async
    if env.ROOT_URL == env.LANDING_APP_ROOT_URL
      client_type = "landing-app"
    else
      client_type = "web-app"