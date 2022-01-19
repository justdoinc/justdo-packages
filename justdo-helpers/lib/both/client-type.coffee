_.extend JustdoHelpers,
  getClientType: (env) ->
    if Meteor.isServer and not env?
      env = process.env
    
    # We get env as an argument to avoid making this func async
    if env.ROOT_URL == env.LANDING_APP_ROOT_URL
      client_type = "landing-app"
    else
      client_type = "web-app"

    return client_type