SimpleSchema.messages({
  "emptyArrayNotAllowed": "Empty array is not allowed"
});

_.extend JustdoPushNotifications,
  push_notification_token_schema: new SimpleSchema
    network_id:
      label: "First name"
      type: String
      allowedValues: ["fcm", "apns"]

    device_id:
      label: "Device ID"
      type: String
      max: 1000

    reg_time:
      label: "Registration time"

      type: Date

      optional: true

      autoValue: ->
        if @isUpdate
          return new Date()
        else if @isInsert
          return new Date()
        else if @isUpsert
          return {$setOnInsert: new Date()}
        else
          @unset()

        return

  _pn_users_via_firebase_args_schema: new SimpleSchema
    message_type:
      # the message type, use dash separated types. e.g.: "chat-msg", "prj-inv"

      type: String

    title:
      # The push notification message title that will be presented to the user

      type: String

      optional: true

    body:
      # The push notification message body.
      type: String

    networks:
      # if unset we will send the message to devices of all networks registered for
      # the listed recepients_ids otherwise, we will limit the submission only to the
      # listed networks (users without listed devices for the network won't receive
      # a notificatino).
      #
      # Note: We support the following "Pseudo" networks:
      #
      #   "mobile": will be replaced with: "fcm", "apns"

      type: [String]

      autoValue: ->
        if not @isSet
          return []
        else
          _networks = []

          for network_id in @value
            if network_id == "mobile"
              _networks.push "apns"
              _networks.push "fcm"
            else 
              _networks.push network_id

          return _networks

    recipients_ids:
      # The users that should receive the push notification. Push notifications will be sent
      # to all of their devices that matches the networks arg.

      type: [String]

      custom: ->
        if _.isEmpty @value
          return "emptyArrayNotAllowed"

        return undefined

    data:
      # Additional data to add to the message data obj.
      # Fields listed under JustdoPushNotifications._firebase_pn_forbidden_data_fields will be removed.

      type: Object

      blackbox: true

      autoValue: ->
        if not @isSet
          return {}
        else
          data = _.extend {}, @value

          for forbidden_data_field of JustdoPushNotifications._firebase_pn_forbidden_data_fields
            delete data[forbidden_data_field]

          return data

  # All the following fields will be removed from args.data object provided to 
  # pnUsersViaFirebase
  _firebase_pn_forbidden_data_fields:
    pn_message_type: true
    message_type: true
    recipient: true
    message: true
    body: true
    title: true
    pcloud: true

