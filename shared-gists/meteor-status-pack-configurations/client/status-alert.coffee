status_messages =
  connected: "Connected"
  connecting: "Connecting..."
  failed: "Connection lost"
  waiting: "Connection lost,"
  offline: "Offline mode."

Template.status_alert.helpers
  showStatus: ->
    meteor_status = Meteor.status()
    current_status = meteor_status.status

    if current_status in ["failed", "waiting", "offline"]
      return true
    else if meteor_status.retryCount != 0 and 
              current_status == "connecting"
      # Failed to reconnect and attempting again - keep showing
      return true

    return false

  justdoStatusMessage: ->
    return status_messages[Meteor.status().status]