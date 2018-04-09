Template.involuntary_unread_email_chat_notifications_subscription_profile_settings.events
  "click .project-conf-unread-notif-email-subscription": ->
    if Meteor.user().justdo_chat.email_notifications == "once-per-unread"
      APP.justdo_chat.setUnreadNotificationsSubscription "email", "off"
    else
      APP.justdo_chat.setUnreadNotificationsSubscription "email", "once-per-unread"

    return

Template.involuntary_unread_email_chat_notifications_subscription_profile_settings.helpers
  isSubscribed: -> Meteor.user().justdo_chat.email_notifications == "once-per-unread"
