share.channel_types = []

share.channel_type_to_channels_constructors = {}

share.channel_types_conf = {}

_.extend JustdoChat,
  registerChannelType: (conf) ->
    # We assume conf is valid!

    # WE ASSUME JustdoChat.registerChannelType() is called before the JustdoChat objects init!!!
    # on schemas.coffee 

    {
      channel_type, # should be == @channel_type in client/server constructor
      channel_type_camel_case, # should be the same as the camel case form used beofre the client/server constructors names
      channel_identifier_fields_simple_schema,
      channel_augemented_fields_simple_schema
    } = conf

    share.channel_types.push channel_type

    share.channel_types_conf[channel_type] = conf

    share.channel_type_to_channels_constructors[channel_type] =
      client: "#{channel_type_camel_case}ChannelClient"
      server: "#{channel_type_camel_case}ChannelServer"

    return

  getChannelTypeConf: (channel_type) ->
    return share.channel_types_conf[channel_type]