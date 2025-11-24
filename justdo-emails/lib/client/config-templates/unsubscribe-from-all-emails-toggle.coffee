Template.justdo_emails_unsubscribe_from_all_emails_toggle.helpers
  isSubscribed: -> 
    tpl = Template.instance()
    return JustdoHelpers.isUserUnsubscribedFromAllEmailNotifications()

Template.justdo_emails_unsubscribe_from_all_emails_toggle.events
  "click .justdo-email-global-notifications-toggle": (e, tpl) ->
    current_value = JustdoHelpers.isUserUnsubscribedFromAllEmailNotifications()
    new_value = not current_value

    modifier = 
      $set:
        "profile.unsubscribe_from_all_email_notifications": new_value
    Meteor.users.update Meteor.userId(), modifier

    return
