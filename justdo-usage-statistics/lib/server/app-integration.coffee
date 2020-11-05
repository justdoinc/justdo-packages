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

# APP.justdo_usage_statistics = new JustdoUsageStatistics()

# **Method B:** If you are depending on env variables to decide whether or not to load
# this package, or even if you use them inside the constructor, you need to wait for
# them to be ready, and it is better done here.

APP.getEnv (env) ->
  # If an env variable affect this package load, check its value here
  # remember env vars are Strings

  options =
    devops_public_key: (env.DEVOPS_PUBLIC_KEY or "").replace(/\\n/g, "\n").trim()
    usage_statistics_level: env.JUSTDO_USAGE_STATISTICS or "basic"

  if options.usage_statistics_level.trim() == "none"
    APP.logger.debug "[justdo-usage-statistics] Disabled"

    return

  APP.justdo_usage_statistics = new JustdoUsageStatistics(options)

  return