_.extend JustdoChat.prototype,
  _setupPublications: ->
    self = @

    Meteor.publish "jdcSubscribeChannelMessages", (channel_type, channel_identifier, options) -> # Note the use of -> not =>, we need @userId
      # Returns both teh messages cursor and a cursor to the channel document, that can be used
      # by the client to determine the channel_id and other information about the channel.

      # Security note:
      #
      # channel_type is checked thoroughly by @generateServerChannelObject
      # channel_identifier is checked thoroughly by the channel object constructor on init.
      # options structures is thoroughly checked by channel_obj.getChannelMessagesCursor()

      self.requireAllowedChannelType(channel_type)
      check channel_identifier, Object
      check options, Match.Maybe(Object)

      channel_obj = self.generateServerChannelObject(channel_type, channel_identifier, @userId)

      return [channel_obj.getChannelMessagesCursor(options), channel_obj.getChannelDocCursor()]
