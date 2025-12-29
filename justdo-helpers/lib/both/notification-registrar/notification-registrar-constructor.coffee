NotificationRegistrarOptionsSchema = new SimpleSchema
  user_preference_subdocument_id:
    # The id of the subdocument we create under user document to hold user preferences
    # For example, `user.justdo_emails` is created to hold user email preferences.
    type: String
  
  label_i18n:
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
  "user_config_options.priority":
    type: Number
  
  custom_options_schema:
    type: SimpleSchema
    optional: true
NotificationRegistrar = (options) ->
  {cleaned_val} =
    JustdoHelpers.simpleSchemaCleanAndValidate(
      NotificationRegistrarOptionsSchema,
      options,
      {throw_on_error: true}
    )
  options = cleaned_val
  @options = options

  @custom_options_schema = @options.custom_options_schema

  @notification_categories = {}
  @notifications = {}
  @user_config_section_id = @options.user_config_options._id
  
  @_setupUsersSchema()
  @_setupUserConfigSection()
  @_setupHashRequestHandler()
  
  return @
  
_.extend NotificationRegistrar.prototype,
  _setupUsersSchema: ->
    user_preference_subdocument_id = @options.user_preference_subdocument_id

    users_schema = new SimpleSchema
      "profile.#{user_preference_subdocument_id}":
        type: Object
        optional: true
      "profile.#{user_preference_subdocument_id}.unsubscribe_from_all":
        type: Boolean
        optional: true
        defaultValue: false
      "profile.#{user_preference_subdocument_id}.unsubscribed_notifications_categories":
        type: Array
        optional: true
      "profile.#{user_preference_subdocument_id}.unsubscribed_notifications_categories.$":
        type: String
        optional: true
    Meteor.users.attachSchema users_schema
    return

  _getUserPreferredSubdocumentFields: ->
    fields = 
      "profile.#{@options.user_preference_subdocument_id}": 1
      
    return fields

  _getUserDocWithPreferenceSubdocument: (user_id) ->
    user = Meteor.users.findOne(user_id, {fields: @_getUserPreferredSubdocumentFields()})
    
    return user
  
  _extractUserPreferenceSubdocument: (user) ->
    if not user?
      throw new Meteor.Error "missing-argument", "User is not provided"
    
    if _.isString user
      user = @_getUserDocWithPreferenceSubdocument user
    if not user?
      throw new Meteor.Error "unknown-user"
    
    return user.profile[@options.user_preference_subdocument_id]

  _setupUserConfigSection: ->
    if not Meteor.isClient
      return

    JustdoHelpers.hooks_barriers.runCbAfterBarriers "post-user-config-ui-init", =>
      if not (user_config_ui = APP.modules.main.user_config_ui)?
        return

      user_config_options = @options.user_config_options

      user_config_ui.registerConfigSection @user_config_section_id,
        priority: user_config_options.priority

      user_config_ui.registerConfigTemplate "unsubscribe-from-all",
        section: @user_config_section_id
        template: "notification_registrar_user_config_toggle"
        template_data:
          is_main_toggle: true
          registrar: @
          user_preference_subdocument_id: @options.user_preference_subdocument_id
          label_i18n: @options.label_i18n
        priority: 0

      return

    return

  _getDashSepUserPreferenceSubdocumentId: ->
    return JustdoHelpers.underscoreSepTo "-", @options.user_preference_subdocument_id

  _setupHashRequestHandler: ->
    if Meteor.isClient
      APP.executeAfterAppLibCode =>
        if not APP.hash_requests_handler
          APP.logger.info "No APP.hash_requests_handler available, skipping hash request handler setup"

          return

        dash_sep_user_preference_subdocument_id = @_getDashSepUserPreferenceSubdocumentId()
        
        APP.hash_requests_handler.addRequestHandler "unsubscribe-from-#{dash_sep_user_preference_subdocument_id}", (args) =>
          notification_category = args["notification-category"]

          if _.isEmpty notification_category
            APP.logger.warn "Hash request: unsubscribe-from-#{dash_sep_user_preference_subdocument_id}: received with no notification-category argument, ignoring request"
            return
          
          notification_category = JustdoHelpers.dashSepTo "_", notification_category
          
          if notification_category is "all"
            @disableAllNotificationsForUser Meteor.userId()
            bootbox_message = TAPi18n.__ "successfully_unsubscribed_from_all_notifications"

          else
            @unsubscribeUserFromNotificationCategory Meteor.userId(), notification_category
            notification_category_label = TAPi18n.__ @requireNotificationCategory(notification_category).label_i18n
            bootbox_message = TAPi18n.__ "successfully_unsubscribed_from_notification_category", {notification_category_label}

          bootbox.alert(bootbox_message)

          return
        
    return
  
  getHashRequestStringForUnsubscribe: (notification_category_id) ->
    dash_sep_user_preference_subdocument_id = @_getDashSepUserPreferenceSubdocumentId()
    return "&hr-id=unsubscribe-from-#{dash_sep_user_preference_subdocument_id}&hr-notification-category=#{JustdoHelpers.underscoreSepTo "-", notification_category_id}"

  _shouldRegisterToggleForNotificationCategory: (notification_category_id) ->
    notification_category = @requireNotificationCategory(notification_category_id)
    notifications_under_category = @getNotificationsUnderCategory(notification_category_id)

    is_notifications_empty = _.isEmpty notifications_under_category
    is_all_notifications_ignoring_user_preference = _.every notifications_under_category, (notification) =>
      return @isNotificationIgnoringUserUnsubscribePreference notification

    return not is_notifications_empty and not is_all_notifications_ignoring_user_preference

  _isToggleRegisteredForNotificationCategory: (notification_category_id) ->
    if not (user_config_ui = APP.modules.main.user_config_ui)?
      return false
    
    return user_config_ui.getConfigTemplate(@user_config_section_id, notification_category_id)?
    
  _updateNotificationCategoryToggleRegistration: (notification_category_id) ->
    if not Meteor.isClient
      return
      
    notification_category = @requireNotificationCategory(notification_category_id)

    should_setup_toggle = @_shouldRegisterToggleForNotificationCategory(notification_category_id)
    is_toggle_registered = @_isToggleRegisteredForNotificationCategory(notification_category_id)
    
    JustdoHelpers.hooks_barriers.runCbAfterBarriers "post-user-config-ui-init", =>
      if not (user_config_ui = APP.modules.main.user_config_ui)?
        return

      if should_setup_toggle and not is_toggle_registered
        user_config_ui.registerConfigTemplate notification_category_id,
          section: @user_config_section_id
          template: "notification_registrar_user_config_toggle"
          template_data:
            registrar: @
            notification_category_id: notification_category_id
            user_preference_subdocument_id: @options.user_preference_subdocument_id
            label_i18n: notification_category.label_i18n
          priority: notification_category.priority
      
      if not should_setup_toggle and is_toggle_registered
        user_config_ui.unregisterConfigTemplate @user_config_section_id, notification_category_id

      return
      
    return

  registerNotificationCategoryOptionsSchema: new SimpleSchema
    label_i18n:
      # The i18n key for the label to display for this notification toggle
      type: String
    priority:
      # The priority for ordering this toggle in the user config section (lower = higher priority)
      type: Number
  registerNotificationCategory: (notification_category_id, options) ->
    {cleaned_val} =
      JustdoHelpers.simpleSchemaCleanAndValidate(
        @registerNotificationCategoryOptionsSchema,
        options,
        {throw_on_error: true}
      )
    notification_category_def = cleaned_val
    notification_category_def._id = notification_category_id

    if @getNotificationCategory(notification_category_id)?
      throw new Meteor.Error "invalid-argument", "Notification category with id #{notification_category_def._id} already registered"

    @notification_categories[notification_category_def._id] = notification_category_def

    return
  
  unregisterNotificationCategory: (notification_category_id) ->
    @notification_categories = _.omit @notification_categories, notification_category_id

    for notification_def in @getNotificationsUnderCategory(notification_category_id)
      @unregisterNotification(notification_def._id)

    return
  
  getNotificationCategory: (notification_category_id) ->
    return @notification_categories[notification_category_id]
  
  requireNotificationCategory: (notification_category_id) ->
    if not (notification_category = @getNotificationCategory(notification_category_id))?
      throw new Meteor.Error "invalid-argument", "Notification category with id #{notification_category_id} not found"
    
    return notification_category

  registerNotifications: (notification_category, notifications_def) ->
    notification_category_def = @requireNotificationCategory(notification_category)

    if not _.isArray notifications_def
      notifications_def = [notifications_def]

    notificationSchema = new SimpleSchema
      _id:
        type: String
  
      ignore_user_unsubscribe_preference:
        # Any notifications with this flag set to true ignores user preference.
        # It means that the user will still receive the notification even if they unsubscribe from this notification category, or all notifications.
        # This is useful for notifications like "confirm email" or "password recovery".
        type: Boolean
        optional: true
      
      custom_options:
        type: @custom_options_schema
        optional: true

    cleaned_notifications_def = []
    for notification_def in notifications_def
      {cleaned_val} =
        JustdoHelpers.simpleSchemaCleanAndValidate(
          notificationSchema,
          notification_def,
          {throw_on_error: true}
        )
      notification_def = cleaned_val
      cleaned_notifications_def.push notification_def
      
    for notification_def in cleaned_notifications_def
      notification_def.notification_category = notification_category
      if @getNotification(notification_def._id)?
        throw new Meteor.Error "invalid-argument", "Notification with id #{notification_def._id} already registered"
      
      @notifications[notification_def._id] = notification_def

    @_updateNotificationCategoryToggleRegistration(notification_category)

    return
  
  getNotificationsUnderCategory: (notification_category_id) ->
    @requireNotificationCategory(notification_category_id)

    notifications_under_category = _.filter @notifications, (notification) ->
      return notification.notification_category is notification_category_id

    return notifications_under_category
  
  getNotification: (notification_id) ->
    return @notifications[notification_id]
  
  requireNotification: (notification_id) ->
    if not (notification = @getNotification(notification_id))?
      throw new Meteor.Error "invalid-argument", "Notification with id #{notification_id} not found"
      
    return notification
  
  unregisterNotification: (notification_id) ->
    notification_def = @getNotification(notification_id)
    notification_category_id = notification_def.notification_category
    @notifications = _.omit @notifications, notification_id

    @_updateNotificationCategoryToggleRegistration(notification_category_id)

    return

  isUserUnsubscribedFromAllNotifications: (user) ->
    if _.isString user
      user = @_getUserDocWithPreferenceSubdocument user

    if not (user_preference_subdocument = @_extractUserPreferenceSubdocument(user))?
      # If the user_preference_subdocument does not exist, it means the user didn't unsubscribe from any notifications. (i.e. all notifications are subscribed.)
      return false
    
    return user_preference_subdocument.unsubscribe_from_all is true
  
  disableAllNotificationsForUser: (user_id) ->
    modifier =
      $set:
        "profile.#{@options.user_preference_subdocument_id}.unsubscribe_from_all": true

    Meteor.users.update user_id, modifier

    return
  
  enableAllNotificationsForUser: (user_id) ->
    modifier =
      $set:
        "profile.#{@options.user_preference_subdocument_id}.unsubscribe_from_all": false

    Meteor.users.update user_id, modifier

    return
  
  isNotificationIgnoringUserUnsubscribePreference: (notification_def) ->
    return notification_def.ignore_user_unsubscribe_preference is true
  
  isUserUnsubscribedFromNotification: (user, notification_id) ->
    # This method is checks individual notification subscription status,
    # which includes whether this particular notification should ignore user unsubscribe preference.
    # 
    # This is useful for checking whether the notification should be sent to the user.

    notification = @requireNotification(notification_id)
    if @isNotificationIgnoringUserUnsubscribePreference notification
      # Return false if the notification ignores user unsubscribe preference.
      return false
    
    notification_category_def = @requireNotificationCategory(notification.notification_category)
    return @isUserUnsubscribedFromNotificationCategory(user, notification_category_def._id)
  
  isUserUnsubscribedFromNotificationCategory: (user, notification_category_id) ->
    if _.isString user
      user = @_getUserDocWithPreferenceSubdocument user
    
    if @isUserUnsubscribedFromAllNotifications user
      # If the user has unsubscribed from all notifications, return true.
      return true
    
    if not (user_preference_subdocument = @_extractUserPreferenceSubdocument(user))? or _.isEmpty(unsubscribed_notifications_categories = user_preference_subdocument.unsubscribed_notifications_categories)
      # If the `user_preference_subdocument`, or `user_preference_subdocument.unsubscribed_notifications_categories` does not exist,
      # it means the user didn't unsubscribe from any notifications. (i.e. all notifications are subscribed.)
      return false
    
    return notification_category_id in unsubscribed_notifications_categories

  unsubscribeUserFromNotificationCategory: (user_id, notification_category_id) ->
    modifier =
      $addToSet:
        "profile.#{@options.user_preference_subdocument_id}.unsubscribed_notifications_categories": notification_category_id

    Meteor.users.update user_id, modifier

    return
  
  subscribeUserToNotificationCategory: (user_id, notification_category_id) ->
    modifier =
      $pull:
        "profile.#{@options.user_preference_subdocument_id}.unsubscribed_notifications_categories": notification_category_id

    Meteor.users.update user_id, modifier

    return
    
      
_.extend JustdoHelpers,
  NotificationRegistrar: NotificationRegistrar
  createNotificationRegistrar: (options) -> new NotificationRegistrar(options)