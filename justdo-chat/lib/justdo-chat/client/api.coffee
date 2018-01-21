channel_type_to_channels_constructors = share.channel_type_to_channels_constructors

_.extend JustdoChat.prototype,
  _immediateInit: ->
    return

  _deferredInit: ->
    if @destroyed
      return

    return

  generateClientChannelObject: (channel_type, channel_conf) ->
    @requireAllowedChannelType(channel_type)
    check channel_conf, Object

    # See both/static-channel-registrar.coffee
    channel_constructor_name = channel_type_to_channels_constructors[channel_type].client

    conf = {
      justdo_chat: @
      channel_conf: channel_conf
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