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
NotificationRegistrar = (options) ->
  {cleaned_val} =
    JustdoHelpers.simpleSchemaCleanAndValidate(
      NotificationRegistrarOptionsSchema,
      options,
      {throw_on_error: true}
    )
  options = cleaned_val
  @options = options

  @notification_categories = {}
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
      "profile.#{user_preference_subdocument_id}.unsubscribe_from_all":
        type: Boolean
        defaultValue: false
      "profile.#{user_preference_subdocument_id}.unsubscribed_notifications_categories":
        type: Array
        optional: true
      "profile.#{user_preference_subdocument_id}.unsubscribed_notifications_categories.$":
        type: String
        optional: true
    Meteor.users.attachSchema users_schema
    return

  _getUserDocWithPreferenceSubdocument: (user_id) ->
    user = Meteor.users.findOne(user_id, {fields: {"profile.#{@options.user_preference_subdocument_id}": 1}})
    
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

    APP.executeAfterAppLibCode =>
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
            notification_category_label = JustdoHelpers.lcFirst TAPi18n.__ @getNotificationCategory(notification_category).label_i18n
            bootbox_message = TAPi18n.__ "successfully_unsubscribed_from_notification_category", {notification_category_label}

          bootbox.alert(bootbox_message)

          return
        
    return
  
  getHashRequestStringForUnsubscribe: (notification_category_id) ->
    dash_sep_user_preference_subdocument_id = @_getDashSepUserPreferenceSubdocumentId()
    return "&hr-id=unsubscribe-from-#{dash_sep_user_preference_subdocument_id}&hr-notification-category=#{JustdoHelpers.underscoreSepTo "-", notification_category_id}"

  _registerNotificationCategoryToggle: (notification_category_id) ->
    if not Meteor.isClient
      return
      
    notification_category = @requireNotificationCategory(notification_category_id)

    APP.executeAfterAppLibCode =>
      if not (user_config_ui = APP.modules.main.user_config_ui)?
        return

      user_config_ui.registerConfigTemplate notification_category_id,
        section: @user_config_section_id
        template: "notification_registrar_user_config_toggle"
        template_data:
          registrar: @
          notification_category_id: notification_category_id
          user_preference_subdocument_id: @options.user_preference_subdocument_id
          label_i18n: notification_category.label_i18n
        priority: notification_category.priority

      return

    return

  registerNotificationCategoryOptionsSchema: new SimpleSchema
    label_i18n:
      # The i18n key for the label to display for this notification toggle
      type: String
    priority:
      # The priority for ordering this toggle in the user config section (lower = higher priority)
      type: Number
    notifications:
      # The available notifications of the category.
      # For example, in the context of emails, the notifications are the email templates.
      type: Array
    "notifications.$":
      type: String
    notifications_ignoring_user_preference:
      # Any notifications listed here igores user preference.
      # It means that the user will still receive the notification even if they unsubscribe from this notification category, or all notifications.
      # This is useful for notifications like "confirm email" or "password recovery".
      type: Array
      optional: true
    "notifications_ignoring_user_preference.$":
      type: String
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

    # Create a toggle template for this notification in the user config section
    is_all_notifications_ignoring_user_preference = _.size(notification_category_def.notifications_ignoring_user_preference) is _.size(notification_category_def.notifications)
    if not is_all_notifications_ignoring_user_preference
      @_registerNotificationCategoryToggle(notification_category_id)

    return
  
  unregisterNotificationCategory: (notification_category_id) ->
    @notification_categories = _.without @notification_categories, @notification_categories[notification_category_id]

    return
  
  getNotificationCategory: (notification_category_id) ->
    return @notification_categories[notification_category_id]
  
  requireNotificationCategory: (notification_category_id) ->
    if not (notification_category = @getNotificationCategory(notification_category_id))?
      throw new Meteor.Error "invalid-argument", "Notification category with id #{notification_category_id} not found"
    
    return notification_category
  
  getNotificationCategoryByNotificationId: (notification_id) ->
    notification_category = _.find @notification_categories, (notification_category) ->
      return notification_id in notification_category.notifications
    
    return notification_category
  
  requireNotificationCategoryByNotificationId: (notification_id) ->
    if not (notification_category = @getNotificationCategoryByNotificationId(notification_id))?
      throw new Meteor.Error "invalid-argument", "Notification with id #{notification_id} not found"
      
    return notification_category

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
  
  isNotificationIgnoringUserUnsubscribePreference: (notification_id) ->
    is_notification_category_ignoring_user_preference = false

    notification_category_def = @requireNotificationCategoryByNotificationId(notification_id)

    notification_category_has_notifications_ignoring_user_preference = notification_category_def.notifications_ignoring_user_preference?
    if notification_category_has_notifications_ignoring_user_preference
      is_notification_category_ignoring_user_preference = notification_id in notification_category_def.notifications_ignoring_user_preference

    return is_notification_category_ignoring_user_preference

  isUserUnsubscribedFromNotification: (user, notification_id) ->
    # This method is checks individual notification subscription status,
    # which includes whether this particular notification should ignore user unsubscribe preference.
    # 
    # This is useful for checking whether the notification should be sent to the user.
    if @isNotificationIgnoringUserUnsubscribePreference notification_id
      # Return false if the notification ignores user unsubscribe preference.
      return false
    
    notification_category_def = @requireNotificationCategoryByNotificationId(notification_id)
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