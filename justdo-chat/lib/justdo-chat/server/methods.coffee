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

        return channel_obj.sendMessage(message_obj, "txt")

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

      jdcManageSubscribers: (channel_type, channel_identifier, update, options={}) ->
        # Security note:
        #
        # channel_type is checked thoroughly by @generateServerChannelObject
        # channel_identifier is checked thoroughly by the channel object constructor on init.
        # update structures is thoroughly checked by channel_obj.manageSubscribers()

        self.requireAllowedChannelType(channel_type)
        check channel_identifier, Object
        check update, Object
        check options, Match.Maybe Object

        channel_obj = self.generateServerChannelObject(channel_type, channel_identifier, @userId)

        return channel_obj.manageSubscribers(update, options)

      jdcSetBottomWindow: (channel_type, channel_identifier, window_settings) ->
        # Security note:
        #
        # channel_type is checked thoroughly by @generateServerChannelObject
        # channel_identifier is checked thoroughly by the channel object constructor on init.
        # window_settings structures is thoroughly checked by channel_obj.setBottomWindow()

        self.requireAllowedChannelType(channel_type)
        check channel_identifier, Object
        check window_settings, Object

        channel_obj = self.generateServerChannelObject(channel_type, channel_identifier, @userId)

        return channel_obj.setBottomWindow(window_settings)

      jdcRemoveBottomWindow: (channel_type, channel_identifier) ->
        # Security note:
        #
        # channel_type is checked thoroughly by @generateServerChannelObject
        # channel_identifier is checked thoroughly by the channel object constructor on init.

        self.requireAllowedChannelType(channel_type)
        check channel_identifier, Object

        channel_obj = self.generateServerChannelObject(channel_type, channel_identifier, @userId)

        return channel_obj.removeBottomWindow()

      #
      # Notifications subscriptions
      #
      jdcSetUnreadNotificationsSubscription: (notification_type, new_state) ->
        # Security note:
        #
        # notification_type is checked thoroughly by self.setUnreadNotificationsSubscription() .
        # new_state is checked thoroughly by self.setUnreadNotificationsSubscription().

        check notification_type, String

        self.setUnreadNotificationsSubscription(notification_type, new_state, @userId)

        return

    return