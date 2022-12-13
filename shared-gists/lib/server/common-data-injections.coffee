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
  "CDN"
  "MAIL_SENDER_EMAIL"
  "BUGMUNCHER_API_KEY"
  "SUPPORT_JUSTDO_LOAD_PAGINATION"
  "JIRA_INTEGRATION_TYPE"
  "JIRA_INTEGRATION_SERVER_HOST"
  "JIRA_INTEGRATION_OAUTH_CLIENT_ID"
  "JIRA_ROOT_URL_CUSTOM_DOMAIN"
  "JIRA_INTEGRATION_SETTINGS"
  "GA_TRACKING_ID"
  "INBOUND_EMAILS_ENABLED"
  "MAILGUN_DOMAIN_NAME"
  "MAILGUN_PROXY_TYPE_IN_USE"
  "MAILGUN_PROXY_IMAP_PROXY_EMAIL_ADDRESS"
  "LANDING_PAGE_CUSTOM_SIGN_UP_MESSAGE"
  "LANDING_PAGE_CUSTOM_SIGN_IN_MESSAGE"
  "ALLOW_ACCOUNTS_TO_CHANGE_EMAIL"
  "ALLOW_ACCOUNTS_PASSWORD_BASED_LOGIN"
  "GOOGLE_DOCS_ENABLED"
  "GOOGLE_OAUTH_LOGIN_ENABLED"
  "AZURE_AD_OAUTH_LOGIN_ENABLED"
  "TASKS_FILES_UPLOAD_ENABLED"
  "FILESTACK_MAX_FILE_SIZE_BYTES"
  "FILESTACK_KEY"
  "JUSTDO_LABS_FEATURES_ENABLED"
  "JUSTDO_FILES_ENABLED"
  "JUSTDO_FILES_MAX_FILESIZE"
  "SITE_ADMINS_ENABLED"
  "SITE_ADMINS_CONF"
  "ZENDESK_ENABLED"
  "ZENDESK_HOST"
  "FROALA_ACTIVATION_KEY"
  "DEVELOPMENT_MODE"
  "ROLLBAR_ENABLED"
  "ROLLBAR_CLIENT_ACCESS_TOKEN"
  "JUSTDO_ANALYTICS_ENABLED"
  "RECAPTCHA_SUPPORTED"
  "RECAPTCHA_MAX_ATTEMPTS_WITHOUT"
  "RECAPTCHA_V2_CHECKBOX_SITE_KEY"
  "RECAPTCHA_V2_ANDROID_SITE_KEY"
  "PASSWORD_STRENGTH_MINIMUM_CHARS"
  "USER_LOGIN_RESUME_TOKEN_TTL_MS"
  "UI_CUSTOMIZATIONS"
  "ALLOW_UPDATES_MODAL"
]

if JustdoHelpers.permitAppVersionExposeToClient()
  env_vars_to_expose.push "APP_VERSION"
  
getExposedClientEnvVars = ->
  return _.pick process.env, env_vars_to_expose

# push current "env" to the client
app_routes.middleware (req, res, next) ->
  # Expose environment variables that should be available in the client
  InjectData.pushData req, "env", getExposedClientEnvVars()

  next()

  return

static_net_if = {}

if process.env.QUERY_AND_EXPOSE_AWS_MACHINE_INFO_TO_NET_IF == "true"
  # At the moment we only expose local-ipv4, into net-if.aws-local-ipv4

  static_net_if["aws-local-ipv4"] = "LOADING..."

  aws_meta_data_obj = {}
  JustdoAnalytics.prototype._addAWSMetaDataToEnvObj aws_meta_data_obj, ->
    static_net_if["aws-local-ipv4"] = aws_meta_data_obj.aws["local-ipv4"]

    return

Meteor.publish null, ->
  @added("JustdoSystem", "env", getExposedClientEnvVars())

  @added("JustdoSystem", "net-if", _.extend {}, static_net_if, {ips: JustdoHelpers.getNetworkInterfacesIps(), "x-forwarded-for": @connection.httpHeaders["x-forwarded-for"], "conn-id": @connection.id})

  @ready()

  return
