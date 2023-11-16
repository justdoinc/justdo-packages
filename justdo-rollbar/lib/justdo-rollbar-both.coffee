load = (env) ->
  if env.ROLLBAR_ENABLED is "true"
    if _.isEmpty(env.ROLLBAR_CLIENT_ACCESS_TOKEN)
      console.warn "[justdo-rollbar] Couldn't load Rollbar, ROLLBAR_CLIENT_ACCESS_TOKEN env var is empty"

      # Stop load
      return

    JustdoRollbar.enabled = true
    JustdoRollbar.host = env.ROLLBAR_CLIENT_ACCESS_TOKEN
    JustdoRollbar.env = env.LANDING_APP_ROOT_URL
    JustdoRollbar.ver = env.APP_VERSION

    JustdoRollbar.init() # we init only if enabled. Note, environment specific init
  else
    JustdoRollbar.enabled = false

if Meteor.isServer
  env = process.env

  load(env)