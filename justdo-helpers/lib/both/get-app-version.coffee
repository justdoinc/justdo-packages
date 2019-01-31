_.extend JustdoHelpers,
  getAppVersion: (only_if_exposed=true) ->
    # On the server side:
    #
    #   Return the value of the environment variable APP_VERSION if:
    #     * It exists, and
    #     * It isn't empty
    #     * only_if_exposed arg is false, or
    #       * The EXPOSE_APP_VERSION env var exist
    #       * The EXPOSE_APP_VERSION is a sting with the value "true" (case
    #       insensitive)
    #
    #   In any other case, undefined is returned
    #
    # On the client side:
    #
    #   Returns the value in env.APP_VERSION (only_if_exposed is ignored client side).

    if Meteor.isServer
      if (not only_if_exposed) or ((expose_app_version = process.env?.EXPOSE_APP_VERSION)? and /^true$/i.test(expose_app_version))
        if (app_version = process.env?.APP_VERSION)? and not _.isEmpty(app_version)
          return app_version

      return undefined

    if Meteor.isClient
      return env.APP_VERSION

  permitAppVersionExposeToClient: ->
    # will return true only if env var APP_VERSION exists and can be exposed

    return JustdoHelpers.getAppVersion()?