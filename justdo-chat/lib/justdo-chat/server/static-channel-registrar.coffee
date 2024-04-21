share.channel_types_server_specific_conf = {}

_.extend JustdoChat,
  registerChannelTypeServerSpecific: (conf) ->
    # We assume conf is valid! and conf.channel_type equals to the one provided to the
    # both registrar!

    share.channel_types_server_specific_conf[conf.channel_type] = conf

    return