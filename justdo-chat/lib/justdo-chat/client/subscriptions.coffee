_.extend JustdoChat.prototype,
  subscribeChannelMessages: (channel_type, channel_identifier, options, callbacks) ->
    @requireAllowedChannelType(channel_type)
    check channel_identifier, Object
    check options, Object

    return Meteor.subscribe "jdcChannelMessages", channel_type, channel_identifier, options, callbacks

  subscribeSubscribedUnreadChannelsCount: (callbacks) ->
    return Meteor.subscribe "jdcSubscribedUnreadChannelsCount", callbacks

  subscribeSubscribedChannelsRecentActivity: (options, callbacks) ->
    if not options?
      options = {}

    check options, Object

    return Meteor.subscribe "jdcSubscribedChannelsRecentActivity", options, callbacks

  subscribeBottomWindows: (options, callbacks) ->
    if not options?
      options = {}

    check options, Object

    return Meteor.subscribe "jdcBottomWindows", options, callbacks

  jdcBotsInfo: (callbacks) ->
    return Meteor.subscribe "jdcBotsInfo", callbacks
