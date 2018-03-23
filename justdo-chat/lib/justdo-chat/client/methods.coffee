max_task_length = JustdoChat.schemas.MessagesSchema._schema.body.max

_.extend JustdoChat.prototype,
  sendMessage: (channel_type, channel_identifier, message_obj, cb) ->
    trimmed_body_length = message_obj.body?.trim().length

    if trimmed_body_length == 0
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

  manageSubscribers: (channel_type, channel_identifier, update, cb) ->
    Meteor.call "jdcManageSubscribers", channel_type, channel_identifier, update, cb

  #
  # Bottom windows
  #
  setBottomWindow: (channel_type, channel_identifier, window_settings, cb) ->
    Meteor.call "jdcSetBottomWindow", channel_type, channel_identifier, window_settings, cb

  removeBottomWindow: (channel_type, channel_identifier, cb) ->
    Meteor.call "jdcRemoveBottomWindow", channel_type, channel_identifier, cb