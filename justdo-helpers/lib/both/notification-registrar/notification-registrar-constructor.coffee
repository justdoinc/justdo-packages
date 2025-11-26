
NotificationRegistrarOptionsSchema = new SimpleSchema
  user_preference_subdocument_id:
    # The id of the subdocument we create under user document to hold user preferences
    # For example, `user.justdo_emails` is created to hold user email preferences.
    type: String
  
  user_config_options:
    # The options we pass to `APP.modules.main.user_config_ui.registerConfigSection`
    # so that the toggle will appear in the user's dropdown.
    #
    # An item will be setup under this section to allow user unsubscribe from all the notifications
    # under this registrar.
    #
    # When a notification is registered, a toggle that allows user to unsubscribe from that particular
    # notification will also be registered in the same section.
    type: Object
  "user_config_options._id":
    type: String
  "user_config_options.title":
    type: String
    optional: true
  "user_config_options.priority":
    type: Number
NotificationRegistrar = (options) ->
  {cleaned_val} =
    JustdoHelpers.simpleSchemaCleanAndValidate(
      NotificationRegistrarOptionsSchema,
      options,
      {throw_on_error: true}
    )
  options = cleaned_val
  @options = options

  @notification_items = {}
  
  @_setupUsersSchema()
  
  return @
  
_.extend NotificationRegistrar.prototype,
  _setupUsersSchema: ->
    user_preference_subdocument_id = @options.user_preference_subdocument_id

    users_schema = new SimpleSchema
      [user_preference_subdocument_id]:
        type: Object
      "#{user_preference_subdocument_id}.unsubscribe_from_all":
        type: Boolean
        defaultValue: false
      "#{user_preference_subdocument_id}.unsubscribed_notifications":
        type: Array
        optional: true
      "#{user_preference_subdocument_id}.unsubscribed_notifications.$":
        type: String
        optional: true
    Meteor.users.attachSchema users_schema
    return
  
  registerNotificationOptionsSchema: new SimpleSchema
    user_preference_field_id:
      # The field to store in `user_preference_subdocument_id.unsubscribed_notifications` array if the user decides to unsubscribe from this notification.
      type: String
    template:
      type: String
    ignore_user_unsubscribe_preference:
      # If true, the user will still receive the notification even if they unsubscribe from all notifications.
      # This is useful for notifications like "confirm email" or "password recovery".
      type: Boolean
      optional: true

  registerNotification: (notification_id, options) ->
    {cleaned_val} =
      JustdoHelpers.simpleSchemaCleanAndValidate(
        @registerNotificationOptionsSchema,
        options,
        {throw_on_error: true}
      )
    notification_def = cleaned_val
    notification_def._id = notification_id

    if @notification_items[notification_def._id]?
      throw new Meteor.Error "invalid-argument", "Notification with id #{notification_def._id} already registered"
    
    @notification_items[notification_def._id] = notification_def

    # Create a toggle template for this notification in the user config section
    if Meteor.isClient
      @_createUserConfigToggleTemplate(notification_id, notification_def)

    return
  
  unregisterNotification: (notification_id) ->
    @notification_items = _.without @notification_items, @notification_items[notification_id]

    return
  
  getNotification: (notification_id) ->
    return @notification_items[notification_id]
  
  requireNotification: (notification_id) ->
    if not (notification_item = @getNotification(notification_id))?
      throw new Meteor.Error "invalid-argument", "Notification with id #{notification_id} not found"
      
    return notification_item
  
  isNotificationIgnoringUserUnsubscribePreference: (notification_id) ->
    notification_item = @requireNotification(notification_id)
    return notification_item.ignore_user_unsubscribe_preference is true

  _getUserDocWithPreferenceSubdocument: (user_id) ->
    user = Meteor.users.findOne(user_id, {fields: {[@options.user_preference_subdocument_id]: 1}})
    
    return user
  
  _extractUserPreferenceSubdocument: (user) ->
    if not user?
      throw new Meteor.Error "missing-argument", "User is not provided"
    
    if _.isString user
      user = @_getUserDocWithPreferenceSubdocument user
    if not user?
      throw new Meteor.Error "unknown-user"
    
    return user[@options.user_preference_subdocument_id]

  isUserUnsubscribedFromAllNotifications: (user) ->
    if _.isString user
      user = @_getUserDocWithPreferenceSubdocument user

    if not (user_preference_subdocument = @_extractUserPreferenceSubdocument(user))?
      # If the user_preference_subdocument does not exist, it means the user didn't unsubscribe from any notifications. (i.e. all notifications are subscribed.)
      return false
    
    return user_preference_subdocument.unsubscribe_from_all is true
  
  isUserUnsubscribedFromNotification: (user, notification_id) ->
    if @isNotificationIgnoringUserUnsubscribePreference notification_id
      # Return false if the notification is ignoring user unsubscribe preference.
      return false
    
    if _.isString user
      user = @_getUserDocWithPreferenceSubdocument user
    
    if @isUserUnsubscribedFromAllNotifications user
      # If the user has unsubscribed from all notifications, return true.
      return true
    
    notification_item = @requireNotification(notification_id)
    if not (user_preference_subdocument = @_extractUserPreferenceSubdocument(user))? or _.isEmpty(unsubscribed_notifications = user_preference_subdocument.unsubscribed_notifications)
      # If the `user_preference_subdocument`, or `user_preference_subdocument.unsubscribed_notifications` does not exist,
      # it means the user didn't unsubscribe from any notifications. (i.e. all notifications are subscribed.)
      return false
    
    return notification_item.user_preference_field_id in unsubscribed_notifications
  
    
      
_.extend JustdoHelpers,
  NotificationRegistrar: NotificationRegistrar
  createNotificationRegistrar: (options) -> new NotificationRegistrar(options)