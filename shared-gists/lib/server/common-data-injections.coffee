app_routes = Picker.filter (req, res) ->
  # Based on: https://github.com/meteorhacks/fast-render/blob/392ca0256f22a22e844a3b8ac5b323a75d83f5f2/lib/server/utils.js
  url = req.url

  if url == '/favicon.ico' or url == '/robots.txt'
    return false

  if url == '/app.manifest'
    return false

  if RoutePolicy.classify(url)
    return false

  /html/.test req.headers['accept']

# Note that change to environment variables and server restart
# won't trigger clients reload if no changes made to js/css.

env_vars_to_expose = [
  "ENV"
  "ROOT_URL"
  "WEB_APP_ROOT_URL"
  "LANDING_APP_ROOT_URL"
  "BUGMUNCHER_API_KEY"
  "GA_TRACKING_ID"
  "INBOUND_EMAILS_ENABLED"
  "MAILGUN_DOMAIN_NAME"
  "GOOGLE_OAUTH_LOGIN_ENABLED"
  "TASKS_FILES_UPLOAD_ENABLED"
  "FILESTACK_KEY"
  "JUSTDO_LABS_FEATURES_ENABLED"
  "ZENDESK_ENABLED"
  "ZENDESK_HOST"
  "ROLLBAR_ENABLED"
  "ROLLBAR_CLIENT_ACCESS_TOKEN"
  "JUSTDO_ANALYTICS_ENABLED"
  "RECAPTCHA_SUPPORTED"
  "RECAPTCHA_MAX_ATTEMPTS_WITHOUT"
  "RECAPTCHA_V2_CHECKBOX_SITE_KEY"
  "RECAPTCHA_V2_ANDROID_SITE_KEY"
]

if JustdoHelpers.permitAppVersionExposeToClient()
  env_vars_to_expose.push "APP_VERSION"
  
getExposedClientEnvVars = ->
  return _.pick process.env, env_vars_to_expose

# push current "env" to the client
app_routes.middleware (req, res, next) ->
  # Expose environment variables that should be available in the client
  InjectData.pushData res, "env", getExposedClientEnvVars()

  next()

  return

Meteor.publish null, ->
  @added("JustdoSystem", "env", getExposedClientEnvVars())

  @ready()

  return
