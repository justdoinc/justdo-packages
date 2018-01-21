_.extend JustdoChat.prototype,
  subscribeChannelMessages: (channel_type, channel_identifier, options, callbacks) ->
    @requireAllowedChannelType(channel_type)
    check channel_identifier, Object
    check options, Object

    return Meteor.subscribe "jdcSubscribeChannelMessages", channel_type, channel_identifier, options, callbacks