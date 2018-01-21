channel_type_to_channels_constructors = share.channel_type_to_channels_constructors

_.extend JustdoChat.prototype,
  generateServerChannelObject: (channel_type, channel_identifier, user_id) ->
    @requireAllowedChannelType(channel_type)
    check channel_identifier, Object

    @requireUserProvided(user_id) # At the moment we don't support generate by the system, so user_id is necessary

    # See both/static-channel-registrar.coffee
    channel_constructor_name = channel_type_to_channels_constructors[channel_type].server

    conf = {
      justdo_chat: @
      performing_user: user_id
      channel_identifier: channel_identifier
    }

    return new share[channel_constructor_name](conf)

  destroy: ->
    if @destroyed
      @logger.debug "Destroyed already"

      return

    _.each @_on_destroy_procedures, (proc) -> proc()

    @destroyed = true

    @logger.debug "Destroyed"

    return