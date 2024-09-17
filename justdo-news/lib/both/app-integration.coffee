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

# APP.justdo_news = new JustdoNews()

# **Method B:** If you are depending on env variables to decide whether or not to load
# this package, or even if you use them inside the constructor, you need to wait for
# them to be ready, and it is better done here.

# APP.getEnv (env) ->
  # If an env variable affect this package load, check its value here
  # remember env vars are Strings

options = {register_news_routes: false}

if Meteor.isServer
  env = process.env
else
  env = window.env

# Logic taken from JustdoHelpers.getClientType
if env.ROOT_URL is env.LANDING_APP_ROOT_URL
  # Set register_news_routes to true if we're in landing app
  options.register_news_routes = true

# Originally, the JustdoNews package was created to be a news package, but we
# ended up using it as a CRM package. So, we're going to create some aliases
# to make it easier to use the CRM features.
APP.justdo_news = new JustdoNews(options)
APP.justdo_crm = APP.justdo_news