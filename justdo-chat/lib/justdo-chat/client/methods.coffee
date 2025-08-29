max_task_length = JustdoChat.schemas.MessagesSchema._schema.body.max

_.extend JustdoChat.prototype,
  sendMessage: (channel_type, channel_identifier, message_obj, cb) ->
    trimmed_body_length = message_obj.body?.trim().length or 0
    files_count = message_obj.files?.length or 0
    is_message_obj_empty = (trimmed_body_length is 0) and (files_count is 0)

    if is_message_obj_empty
      # Ignore attempt to submit empty messages
      return

    if trimmed_body_length > max_task_length
      cb(@_error "invalid-message", "Message can't be longer than #{max_task_length} charecters")

      return

    Meteor.call "jdcSendMessage", channel_type, channel_identifier, message_obj, cb

  setChannelUnreadState: (channel_type, channel_identifier, new_state, cb) ->
    @emit "pre-set-channel-unread-state-request", channel_type, channel_identifier, new_state

    Meteor.call "jdcSetChannelUnreadState", channel_type, channel_identifier, new_state, cb

  markAllChannelsAsRead: (cb) ->
    # XXX TODO: ONLY IF REQUIRED

    Meteor.call "jdcMarkAllChannelsAsRead", cb

  manageSubscribers: (channel_type, channel_identifier, update, options, cb) ->
    if _.isFunction options
      cb = options
      options = {}
    Meteor.call "jdcManageSubscribers", channel_type, channel_identifier, update, options, cb

  #
  # Bottom windows
  #
  setBottomWindow: (channel_type, channel_identifier, window_settings, cb) ->
    Meteor.call "jdcSetBottomWindow", channel_type, channel_identifier, window_settings, cb

  removeBottomWindow: (channel_type, channel_identifier, cb) ->
    Meteor.call "jdcRemoveBottomWindow", channel_type, channel_identifier, cb

  #
  # Notifications subscriptions
  #
  setUnreadNotificationsSubscription: (notification_type, new_state, cb) ->
    Meteor.call "jdcSetUnreadNotificationsSubscription", notification_type, new_state, cb

    return
