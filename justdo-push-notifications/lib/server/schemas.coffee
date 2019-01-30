_.extend JustdoPushNotifications.prototype,
  _attachCollectionsSchemas: ->
    Meteor.users.attachSchema
      jd_pn_tokens:
        label: "JustDo Push Notifications Tokens"

        type: [JustdoPushNotifications.push_notification_token_schema]

        optional: true 

    return