_.extend JustdoHelpers,
  showSessionTimedoutMessageAndLogout: ->
    bootbox.alert
      message: "<h3 class='mb-4'>Session timed out - please sign in again</h3>"
      className: "bootbox-new-design bootbox-new-design-simple-dialogs-default"
      closeButton: false

    setTimeout ->
      Meteor.logout()
    , 2000

    return