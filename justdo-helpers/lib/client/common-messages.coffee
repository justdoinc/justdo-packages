_.extend JustdoHelpers,
  showSessionTimedoutMessageAndLogout: ->
    APP.getEnv (env) ->
      if JustdoHelpers.getClientType(env) == "web-app" # We show the message only in the web-app
        bootbox.alert
          message: "<h3 class='mb-4'>Session timed out - please sign in again</h3>"
          className: "bootbox-new-design bootbox-new-design-simple-dialogs-default"
          closeButton: false

      setTimeout ->
        Meteor.logout()
      , 2000

      return

    return