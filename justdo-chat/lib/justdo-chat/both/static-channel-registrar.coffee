share.channel_types = []

share.channel_type_to_channels_constructors = {}

share.channel_types_conf = {}

_.extend JustdoChat,
  registerChannelType: (conf) ->
    # We assume conf is valid!

    # WE ASSUME JustdoChat.registerChannelType() is called before the JustdoChat objects init!!!
    # on schemas.coffee 

    conf = _.extend {}, conf # shallow copy

    {
      channel_type, # should be == @channel_type in client/server constructor
      channel_type_camel_case, # should be the same as the camel case form used beofre the client/server constructors names
      recent_activity_supplementary_pseudo_collections
      bottom_windows_supplementary_pseudo_collections
    } = conf

    #
    # Load recent_activity_supplementary_pseudo_collections
    #
    if recent_activity_supplementary_pseudo_collections?
      recent_activity_supplementary_pseudo_collections = _.extend {}, recent_activity_supplementary_pseudo_collections # shallow copy

      for col_id, col_name of recent_activity_supplementary_pseudo_collections
        recent_activity_supplementary_pseudo_collections[col_id] = "JDChatRecentActivity" + col_name # add the common prefix
      conf.recent_activity_supplementary_pseudo_collections = recent_activity_supplementary_pseudo_collections

    #
    # Load bottom_windows_supplementary_pseudo_collections
    #
    if bottom_windows_supplementary_pseudo_collections?
      bottom_windows_supplementary_pseudo_collections = _.extend {}, bottom_windows_supplementary_pseudo_collections # shallow copy

      for col_id, col_name of bottom_windows_supplementary_pseudo_collections
        bottom_windows_supplementary_pseudo_collections[col_id] = "JDChatBottomWindows" + col_name # add the common prefix
      conf.bottom_windows_supplementary_pseudo_collections = bottom_windows_supplementary_pseudo_collections

    share.channel_types.push channel_type

    share.channel_types_conf[channel_type] = conf

    share.channel_type_to_channels_constructors[channel_type] =
      client: "#{channel_type_camel_case}ChannelClient"
      server: "#{channel_type_camel_case}ChannelServer"

    return

  getChannelTypeConf: (channel_type) ->
    return share.channel_types_conf[channel_type]