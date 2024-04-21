_.extend JustdoHelpers,
  getCurrentPlatformName: ->
    if Meteor.isServer
      return "server"

    if Meteor.isClient
      return "client"

    return "unknown"