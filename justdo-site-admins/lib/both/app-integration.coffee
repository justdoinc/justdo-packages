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

# APP.justdo_site_admins = new JustdoSiteAdmins()

# **Method B:** If you are depending on env variables to decide whether or not to load
# this package, or even if you use them inside the constructor, you need to wait for
# them to be ready, and it is better done here.

APP.getEnv (env) ->
  # If an env variable affect this package load, check its value here
  # remember env vars are Strings

  if env.SITE_ADMINS_ENABLED is "true"
    options =
      site_admins_conf: JustdoHelpers.getNonEmptyValuesFromCsv(env.SITE_ADMINS_CONF)
      client_type: JustdoHelpers.getClientType(env)

    if Meteor.isServer
      options.site_admins_emails = JustdoHelpers.getNonEmptyValuesFromCsv(env.SITE_ADMINS_EMAILS)
      options.server_vitals_collection = new Mongo.Collection "server_vitals"

    APP.justdo_site_admins = new JustdoSiteAdmins(options)

    APP.emit "justdo-site-admins-initiated"
  else
    APP.logger.debug "[justdo-site-admins] Disabled"

  return