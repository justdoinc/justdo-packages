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
