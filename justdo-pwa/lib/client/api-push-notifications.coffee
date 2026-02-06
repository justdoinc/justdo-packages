_.extend JustdoPwa.prototype,
  _pn_token_rv: new ReactiveVar null
  _pn_tap_handlers: {}
  _pn_received_handlers: {}
  _pn_pending_tap_action: null

  isNativePlatform: ->
    return window.Capacitor?.isNativePlatform?()

  _getPushNotificationsPlugin: ->
    if not (PushNotifications = window.Capacitor?.Plugins?.PushNotifications)?
      return

    return PushNotifications

  _getPushNotificationsPluginIfNativePlatform: ->
    if not @isNativePlatform()
      @logger.debug "Not running in native app"
      return

    if not (PushNotifications = @_getPushNotificationsPlugin())?
      @logger.debug "PushNotifications plugin not found"
      return

    return PushNotifications

  _setupPushNotificationsRegistration: ->
    if not (PushNotifications = @_getPushNotificationsPluginIfNativePlatform())?
      return

    # Set up listeners BEFORE requesting permissions/registration
    PushNotifications.addListener "registration", (token) =>
      @logger.debug "Received push notification token"
      # Instead of calling `pnRegisterToken` immediately after token registration,
      # we store the token in a reactive var so that we can call `pnRegisterToken`
      # after ensuring that the user is logged in.
      @_pn_token_rv.set token.value
      return
    PushNotifications.addListener "registrationError", (error) =>
      @logger.error "Push notification registration error:", error
      return

    # Request permissions and register
    PushNotifications.requestPermissions()
      .then (result) =>
        if result.receive is "granted"
          @logger.debug "Push notification permissions granted, registering..."
          PushNotifications.register()
        else
          @logger.error "Push notification permissions not granted:", result.receive
        return
      .catch (err) =>
        @logger.error "Error requesting push notification permissions:", err
        return

    Tracker.autorun (computation) =>
      pn_token = @_pn_token_rv.get()
      user_id = Meteor.userId()

      if user_id? and pn_token?
        Meteor.call "pnRegisterToken", "apns",
          network_id: "apns"
          device_id: pn_token
        , (err) =>
          if err?
            @logger.error "Failed to register push notification token:", err
          else
            @logger.debug "Push notification token registered successfully"
          return

        computation.stop()
      return

    return

  _setupPushNotificationsHandlers: ->
    if not (PushNotifications = @_getPushNotificationsPluginIfNativePlatform())?
      return

    # Handle notifications received while app is in foreground
    PushNotifications.addListener "pushNotificationReceived", (notification) =>
      @_processPushNotification notification, "received"
      return

    # Handle notification tap, regardless of whether the app is in foreground or background
    PushNotifications.addListener "pushNotificationActionPerformed", (action) =>
      if action.actionId is "tap"
        @_processPushNotification action.notification, "tap"
      return

    return

  _processPushNotification: (notification, type) ->
    @logger.debug "Processing push notification #{type}:", notification

    check notification, Object
    check type, String
    if type not in ["received", "tap"]
      throw @_error "invalid-argument", "Invalid push notification type: #{type}"

    pn_message_type = notification.data.pn_message_type

    if type is "received"
      handler = @getPushNotificationReceivedHandler(pn_message_type)
      return handler?(notification)
    if type is "tap"
      if (handler = @getPushNotificationTapHandler(pn_message_type))?
        return handler(notification)
      else
        # If no handler found for a tap notification, queue it for later processing.
        # This handles the race condition where a notification tap (e.g. from lock screen
        # cold start) arrives before the tap handler has been registered.
        @logger.debug "No tap handler found for message type #{pn_message_type}, queuing notification"
        @_pn_pending_tap_action = notification

    return

  _registerPushNotificationHandler: (pn_message_type, handler, handlers_map) ->
    check pn_message_type, String
    check handler, Function
    check handlers_map, Object

    if pn_message_type of handlers_map
      throw @_error "invalid-argument", "Push notification handler already registered for message type #{pn_message_type}"

    handlers_map[pn_message_type] = handler
    return
  registerPushNotificationTapHandler: (pn_message_type, handler) ->
    @_registerPushNotificationHandler pn_message_type, handler, @_pn_tap_handlers

    if @_pn_pending_tap_action?.data.pn_message_type is pn_message_type
      @logger.debug "Processing queued tap notification for message type #{pn_message_type}"
      @_processPushNotification @_pn_pending_tap_action, "tap"
      
    return
  registerPushNotificationReceivedHandler: (pn_message_type, handler) ->
    return @_registerPushNotificationHandler pn_message_type, handler, @_pn_received_handlers

  _getPushNotificationHandler: (pn_message_type, handlers_map) ->
    check pn_message_type, String
    check handlers_map, Object

    return handlers_map[pn_message_type]
  getPushNotificationTapHandler: (pn_message_type) ->
    return @_getPushNotificationHandler pn_message_type, @_pn_tap_handlers
  getPushNotificationReceivedHandler: (pn_message_type) ->
    return @_getPushNotificationHandler pn_message_type, @_pn_received_handlers
