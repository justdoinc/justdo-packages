disconnectionsTracker = (con) ->
  con.onClose ->
    if APP.justdo_analytics.isClientConnected(con)
      APP.justdo_analytics.log({cat: "core", act: "connection-closed"}, con)

    return

APP.getEnv (env) ->
  if env.JUSTDO_ANALYTICS_ENABLED == "true"
    Meteor.onConnection disconnectionsTracker