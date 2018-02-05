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
    Meteor.call "jdcSetChannelUnreadState", channel_type, channel_identifier, new_state, cb

  markChannelAsUnread: (channel_type, channel_identifier, cb) ->
    Meteor.call "jdcMarkChannelAsUnread", channel_type, channel_identifier, cb

  markAllChannelsAsRead: (cb) ->
    console.log "TODO: ONLY IF REQUIRED"

    Meteor.call "jdcMarkAllChannelsAsRead", cb

  manageSubscribers: (channel_type, channel_identifier, update, cb) ->
    Meteor.call "jdcManageSubscribers", channel_type, channel_identifier, update, cb
