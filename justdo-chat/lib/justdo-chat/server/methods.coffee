_.extend JustdoChat.prototype,
  _setupMethods: ->
    self = @

    Meteor.methods
      jdcSendMessage: (channel_type, channel_identifier, message_obj) ->
        # Security note:
        #
        # channel_type is checked thoroughly by @generateServerChannelObject
        # channel_identifier is checked thoroughly by the channel object constructor on init.
        # message_obj structures is thoroughly checked by channel_obj.sendMessage()

        self.requireAllowedChannelType(channel_type)
        check channel_identifier, Object
        check message_obj, Object

        channel_obj = self.generateServerChannelObject(channel_type, channel_identifier, @userId)

        return channel_obj.sendMessage(message_obj)

      jdcSetChannelUnreadState: (channel_type, channel_identifier, new_state) ->
        # Security note:
        #
        # channel_type is checked thoroughly by @generateServerChannelObject
        # channel_identifier is checked thoroughly by the channel object constructor on init.

        check new_state, Boolean

        channel_obj = self.generateServerChannelObject(channel_type, channel_identifier, @userId)

        return channel_obj.setChannelUnreadState(new_state)

      jdcMarkAllChannelsAsRead: ->
        # Security note:
        #
        # channel_type is checked thoroughly by @generateServerChannelObject
        # channel_identifier is checked thoroughly by the channel object constructor on init.

        return self.markAllChannelsAsRead(@userId)

      jdcManageSubscribers: (channel_type, channel_identifier, update) ->
        # Security note:
        #
        # channel_type is checked thoroughly by @generateServerChannelObject
        # channel_identifier is checked thoroughly by the channel object constructor on init.
        # update structures is thoroughly checked by channel_obj.sendMessage()

        self.requireAllowedChannelType(channel_type)
        check channel_identifier, Object
        check update, Object

        channel_obj = self.generateServerChannelObject(channel_type, channel_identifier, @userId)

        return channel_obj.manageSubscribers(update)

    return