#
# Publish APP_VERSION, if exists and allowed
#
if (app_version = JustdoHelpers.getAppVersion())?
  # Note that only if exposing of app_version allowed
  # by EXPOSE_APP_VERSION JustdoHelpers.getAppVersion()
  # will return the version, read JustdoHelpers.getAppVersion()
  # docs for more details.

  Meteor.publish null, ->
    @added("JustdoSystem", "app_version", {app_version: app_version})

    @ready()
