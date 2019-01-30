load = (env) ->
  if env.ROLLBAR_ENABLED is "true"
    if _.isEmpty(env.ROLLBAR_CLIENT_ACCESS_TOKEN)
      console.warn "[justdo-rollbar] Couldn't load Rollbar, ROLLBAR_CLIENT_ACCESS_TOKEN env var is empty"

      # Stop load
      return

    JustdoRollbar.enabled = true
    JustdoRollbar.host = env.ROLLBAR_CLIENT_ACCESS_TOKEN

    JustdoRollbar.init() # we init only if enabled. Note, environment specific init
  else
    JustdoRollbar.enabled = false

# Since we don't want the following to be deferred, we don't use
# the APP.getEnv to get the env on the server
if Meteor.isServer
  env = process.env

  load(env)
else
  APP.getEnv (env) ->
    load(env)
