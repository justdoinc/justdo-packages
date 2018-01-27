_.extend JustdoChat.prototype,
  _setupPublications: ->
    self = @

    Meteor.publish "jdcChannelMessages", (channel_type, channel_identifier, options) -> # Note the use of -> not =>, we need @userId
      # Publishes the channel document, if one exists, for the requested channel, and the messages
      # of this channel, according to the provided options.

      # Security note:
      #
      # channel_type is checked thoroughly by @generateServerChannelObject
      # channel_identifier is checked thoroughly by the channel object constructor on init.
      # options structures is thoroughly checked by channel_obj.getChannelMessagesCursor()
      # if @userId is not allowed to access the channel, exception will be thrown in the attempt
      # to generate channel_obj.
      self.requireAllowedChannelType(channel_type)
      check channel_identifier, Object
      check options, Match.Maybe(Object)

      channel_obj = self.generateServerChannelObject(channel_type, channel_identifier, @userId)

      return channel_obj.channelMessagesPublicationHandler(@, options)