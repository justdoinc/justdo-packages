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

# APP.justdo_licensing = new JustdoLicensing()

# **Method B:** If you are depending on env variables to decide whether or not to load
# this package, or even if you use them inside the constructor, you need to wait for
# them to be ready, and it is better done here.

options = {}

if Meteor.isServer
  if process.env.ROOT_URL != "http://localhost:9100/" # That root url is the minifier in our build process, removing this line will break the build
    # The following is a backdoor for case things will go wrong, once confidence will
    # accumlate with justdo-licensing can be removed.

    if process.env.JUSTDO_ENTERPRISE_FEATURES is "true"
      options.jsoned_license = process.env.JUSTDO_LICENSING_LICENSE

      APP.justdo_licensing = new JustdoLicensing(options)
else
  APP.justdo_licensing = new JustdoLicensing(options)
