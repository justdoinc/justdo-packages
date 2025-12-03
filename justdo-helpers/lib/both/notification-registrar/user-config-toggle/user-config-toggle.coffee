# Template for notification toggle in user config UI
#
# Receives data via template_data from registerConfigTemplate:
#
# For main "unsubscribe from all" toggle: 
#   - is_main_toggle: true
#   - registrar: NotificationRegistrar instance
#   - user_preference_subdocument_id: string
#   - label_i18n: string (i18n key for label)
#
# For individual notification toggles:
#   - registrar: NotificationRegistrar instance
#   - user_preference_subdocument_id: string
#   - notification_category_id: string
#   - label_i18n: string (optional, i18n key for label)

Template.notification_registrar_user_config_toggle.onCreated ->
  @isMainToggle = ->
    return @data.is_main_toggle

  @isDisabled = ->
    if @isMainToggle()
      return false
    
    return @isUserUnsubscribedFromAllNotifications()

  @isUserUnsubscribedFromAllNotifications = ->
    return @data.registrar.isUserUnsubscribedFromAllNotifications(Meteor.user())
  
  @isUserUnsubscribedFromNotificationCategory = (notification_category_id) ->
    return @data.registrar.isUserUnsubscribedFromNotificationCategory(Meteor.user(), notification_category_id)
  
  @toggleUserUnsubscribedFromAllNotifications = ->
    if @isUserUnsubscribedFromAllNotifications()
      @data.registrar.enableAllNotificationsForUser(Meteor.userId())
    else
      @data.registrar.disableAllNotificationsForUser(Meteor.userId())
    
    return
  
  @toggleUserUnsubscribedFromNotificationCategory = (notification_category_id) ->
    if @isUserUnsubscribedFromNotificationCategory(notification_category_id)
      @data.registrar.subscribeUserToNotificationCategory(Meteor.userId(), notification_category_id)
    else
      @data.registrar.unsubscribeUserFromNotificationCategory(Meteor.userId(), notification_category_id)

    return

  return

Template.notification_registrar_user_config_toggle.helpers
  isMainToggle: ->
    tpl = Template.instance()

    return tpl.isMainToggle()
    
  isDisabled: ->
    tpl = Template.instance()

    return tpl.isDisabled()

  isSubscribed: ->
    tpl = Template.instance()

    if tpl.isMainToggle()
      # Main toggle: check if user is NOT unsubscribed from all
      return not tpl.isUserUnsubscribedFromAllNotifications()
    else
      # Individual notification toggle: check if user is NOT unsubscribed from this notification
      return not tpl.isUserUnsubscribedFromNotificationCategory(@notification_category_id)

Template.notification_registrar_user_config_toggle.events
  "click .notification-registrar-toggle": (e, tpl) ->
    if tpl.isDisabled()
      return

    if tpl.isMainToggle()
      # Main toggle: toggle unsubscribe_from_all
      tpl.toggleUserUnsubscribedFromAllNotifications()
    else
      # Individual notification toggle
      tpl.toggleUserUnsubscribedFromNotificationCategory(@notification_category_id)

    return

