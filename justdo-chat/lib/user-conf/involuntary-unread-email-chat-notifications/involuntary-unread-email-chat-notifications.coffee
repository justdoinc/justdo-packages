default_email_notifications_state = "once-per-unread"

getUserEmailNotificationsState = ->
  email_notifications = Meteor.user().justdo_chat?.email_notifications

  if not email_notifications?
    email_notifications = default_email_notifications_state

  return email_notifications

Template.involuntary_unread_email_chat_notifications_subscription_profile_settings.events
  "click .project-conf-unread-notif-email-subscription": ->
    email_notifications = getUserEmailNotificationsState()

    if email_notifications == "once-per-unread"
      APP.justdo_chat.setUnreadNotificationsSubscription "email", "off"
    else
      APP.justdo_chat.setUnreadNotificationsSubscription "email", "once-per-unread"

    return

Template.involuntary_unread_email_chat_notifications_subscription_profile_settings.helpers
  isSubscribed: -> getUserEmailNotificationsState() == "once-per-unread"
