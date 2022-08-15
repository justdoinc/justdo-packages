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
  if env.JIRA_INTEGRATION_TYPE.toLowerCase() not in ["cloud", "server"]
    return


  APP.collections.Jira = new Mongo.Collection "jira"

  options =
    projects_collection: APP.collections.Projects
    tasks_collection: APP.collections.Tasks
    jira_collection: APP.collections.Jira

  # XXX To be fetched from env vars
  if Meteor.isServer

    if env.JIRA_INTEGRATION_TYPE.toLowerCase() is "cloud"
      _.extend options,
        # Jira Cloud relavent credentials
        client_id: env.JIRA_INTEGRATION_OAUTH_CLIENT_ID
        client_secret: env.JIRA_INTEGRATION_OAUTH_CLIENT_SECRET
        get_oauth_token_endpoint: "https://auth.atlassian.com/oauth/token"

    if env.JIRA_INTEGRATION_TYPE.toLowerCase() is "server"
      _.extend options,
        # Jira Server relavent credentials
        jira_server_host: env.JIRA_INTEGRATION_SERVER_HOST
        consumer_key: "OAuthKey"
        private_key: env.JIRA_INTEGRATION_OAUTH_SECRET

  APP.justdo_jira_integration = new JustdoJiraIntegration(options)

  return
