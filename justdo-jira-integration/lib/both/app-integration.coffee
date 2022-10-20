# This file is the last file we load for this package and it's loaded in both
# server and client (keep in mind! don't put non-secure code that shouldn't be
# exposed to clients here).
#
# Uncomment to create an instance automatically on server/client init
#
# If you uncomment this, uncomment in package.js the load of meteorspark:app
# package.
#
# Avoid this step in packages that implements pure logic that isn't specific
# to the JustDo app. Pure logic packages should get all the context they need
# to work with collections/other plugins instances/etc. as options.

# **Method A:** If you aren't depending on any env variable just comment the following

# APP.justdo_jira_integration = new JustdoJiraIntegration()

# **Method B:** If you are depending on env variables to decide whether or not to load
# this package, or even if you use them inside the constructor, you need to wait for
# them to be ready, and it is better done here.

APP.getEnv (env) ->
  # If an env variable affect this package load, check its value here
  # remember env vars are Strings
  server_type = env.JIRA_INTEGRATION_TYPE

  if server_type not in ["cloud", "server-oauth1", "server-oauth2"]
    return

  APP.collections.Jira = new Mongo.Collection "jira"

  options =
    projects_collection: APP.collections.Projects
    tasks_collection: APP.collections.Tasks
    jira_collection: APP.collections.Jira
    server_type: server_type

  if Meteor.isServer
    if server_type is "cloud"
      _.extend options,
        # Jira Cloud relavent credentials
        client_id: env.JIRA_INTEGRATION_OAUTH_CLIENT_ID
        client_secret: env.JIRA_INTEGRATION_OAUTH_CLIENT_SECRET
        get_oauth_token_endpoint: "https://auth.atlassian.com/oauth/token"

    if server_type is "server-oauth1"
      _.extend options,
        # Jira Server (oauth1) relavent credentials
        jira_server_host: env.JIRA_INTEGRATION_SERVER_HOST
        consumer_key: "OAuthKey"
        private_key: env.JIRA_INTEGRATION_OAUTH_SECRET.replace /\\n/g, "\n"

    if server_type is "server-oauth2"
      _.extend options,
      # Jira Server (oauth2) relavent credentials
        client_id: env.JIRA_INTEGRATION_OAUTH_CLIENT_ID
        client_secret: env.JIRA_INTEGRATION_OAUTH_CLIENT_SECRET
        jira_server_host: env.JIRA_INTEGRATION_SERVER_HOST
        get_oauth_token_endpoint: new JustdoHelpers.url.URL("/rest/oauth2/latest/token", env.JIRA_INTEGRATION_SERVER_HOST).toString()

  APP.justdo_jira_integration = new JustdoJiraIntegration(options)

  return
