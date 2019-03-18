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

# APP.justdo_recaptcha = new JustdoRecaptcha()

# **Method B:** If you are depending on env variables to decide whether or not to load
# this package, or even if you use them inside the constructor, you need to wait for
# them to be ready, and it is better done here.

APP.getEnv (env) ->
  # If an env variable affect this package load, check its value here
  # remember env vars are Strings

  options =
    supported: env.RECAPTCHA_SUPPORTED is "true"
    max_attempts_without: parseInt(env.RECAPTCHA_MAX_ATTEMPTS_WITHOUT, 10) || undefined
    v2_checkbox_site_key: env.RECAPTCHA_V2_CHECKBOX_SITE_KEY
    v2_checkbox_server_key: env.RECAPTCHA_V2_CHECKBOX_SERVER_KEY
    v2_android_site_key: env.RECAPTCHA_V2_ANDROID_SITE_KEY
    v2_android_server_key: env.RECAPTCHA_V2_ANDROID_SERVER_KEY

  APP.justdo_recaptcha = new JustdoRecaptcha(options)

  return