_.extend JustdoPushNotifications.prototype,
  _immediateInit: ->
    return

  _deferredInit: ->
    # Test
    #
    # @pnUsersViaFirebase
    #   message_type: "chat-msg"

    #   title: "New chat message received"

    #   body: "BODY: New chat message received"

    #   recipients_ids: ["ZgYhc8GEnH5aQWiRr"]

    #   networks: ["mobile"]

    #   data:
    #     x: 1
    #     y: 2

    if @destroyed
      return

    # Defined in allow-deny.coffee
    @_setupAllowDenyRules()

    # Defined in collections-hooks.coffee
    @_setupCollectionsHooks()

    # Defined in collections-indexes.coffee
    @_ensureIndexesExists()

    # Defined in methods.coffee
    @_setupMethods()

    return

  requireUserProvided: (user_id) ->
    if not user_id?
      throw @_error "login-required"

    check(user_id, String)

    return true

  manageToken: (action, pn_network_id, token_obj, user_id) ->
    @requireUserProvided(user_id)

    if action not in ["register", "unregister"]
      throw @_error "invalid-argument", "Invalid argument provided for action - use: register/unregister"

    token_obj = _.extend {}, token_obj, {network_id: pn_network_id} # Shallow copy, and add the network_id property.

    {cleaned_val} =
      JustdoHelpers.simpleSchemaCleanAndValidate(
        JustdoPushNotifications.push_notification_token_schema,
        token_obj,
        {self: @, throw_on_error: true}
      )
    token_obj = cleaned_val

    token_obj.reg_time = new Date()

    update = {}
    if action == "register"
      if not (user_doc = Meteor.users.findOne({_id: user_id}, {fields: {"jd_pn_tokens": 1}}))?
        throw @_error "unknown-user"

      if _.find(user_doc.jd_pn_tokens, (existing_token) -> existing_token.device_id == token_obj.device_id)?
        throw @_error "device-id-already-registered-for-user"
      
      update.$push =
        jd_pn_tokens: token_obj

    if action == "unregister"
      update.$pull =
        "jd_pn_tokens":
          "device_id": token_obj.device_id

    # Use rawCollection since simple schema removes corrupt the $pull request
    APP.justdo_analytics.logMongoRawConnectionOp(Meteor.users._name, "update", {_id: user_id}, update)
    Meteor.users.rawCollection().update {_id: user_id}, update, Meteor.bindEnvironment (err) ->
      if err?
        console.error(err)
      return

    return

  isFirebaseEnabled: -> APP.justdo_firebase.isEnabled()

  pnUsersViaFirebase: (args) ->
    # @_pnUsersViaFirebaseArgsSchema details the args structure
    #
    # Returns an array of objects of the following form:
    #
    # [
    #   {
    #     pn_deferred: The deferred object returned by firebase's .send() api
    #     user_id: The user id to whom this message was sent
    #     device_id: The device id to which we sent the device
    #     network_id: The device's network id
    #   }
    # ]
    #
    # If the @pnUsersViaFirebase() call didn't result in any push notification submission,
    # an empty array will be returned.

    if not @isFirebaseEnabled()
      @logger.warn "@pnUsersViaFirebase(): Firebase is not enabled, ignoring request"

      return

    {cleaned_val} =
      JustdoHelpers.simpleSchemaCleanAndValidate(
        JustdoPushNotifications._pn_users_via_firebase_args_schema,
        args,
        {self: @, throw_on_error: true}
      )
    args = cleaned_val

    message_data =
      pn_message_type: args.message_type

      message: args.body

    if args.title?
      message_data.title = args.title

    if (cloud_domain = JustdoHelpers.getProdDomain()) != "justdo.com"
      # Is private cloud

      message_data.pcloud = cloud_domain

    _.extend message_data, args.data

    base_message =
      data: message_data

    recipients_ids = _.unique args.recipients_ids
    networks = _.unique args.networks

    users_query =
      _id: {$in: recipients_ids}
      jd_pn_tokens: { $exists: true, $ne: [] }

    if not _.isEmpty networks
      users_query["jd_pn_tokens.network_id"] = {$in: networks}

    return_value = []

    Meteor.users.find(users_query, {fields: {jd_pn_tokens: 1}}).forEach (user_doc) =>
      user_device_ids_submitted = {} # To avoid sending more than once in case of data issue in the db

      for token_obj in user_doc.jd_pn_tokens
        if token_obj.network_id not in networks
          # Network isn't target for this pn

          continue

        device_id = token_obj.device_id
        if device_id of user_device_ids_submitted
          # Already submitted to this device id

          continue

        # Copy base message to a new object
        message = _.extend {}, base_message
        message.data = _.extend {}, base_message.data

        user_device_ids_submitted[device_id] = true

        message.to = device_id
        message.data.recipient = user_doc._id

        if token_obj.network_id == "apns"
          message.content_available = true

          message.notification =
            title: message.data.title
            body: message.data.message

        if token_obj.network_id == "fcm"
          # A message received from the Android developer:

          # From firebase documentation:
          # In cases where the message is data-only and the device is in the background or quit, both Android & iOS treat the message as low priority and will ignore it (i.e. no event will be sent). You can however increase the priority by setting the priority to high (Android) and content-available to true(iOS) properties on the payload.

          # in iOS, you are using the Notification + Data type so this isn't an issue, apps will keep receiving notifications in background / closed.

          # for Android, since you are using the data-only. the OS will ignore it. 

          # https://rnfirebase.io/messaging/usage#message-handlers

          message.priority = "high"

        APP.justdo_firebase.send (err, response) ->
          if err?
              console.log("Something has gone wrong!", err)
          else
              console.log("Successfully sent with response: ", response)

          return

        return_value.push
          user_id: user_doc._id
          device_id: device_id
          network_id: token_obj.network_id

      return

    return return_value
