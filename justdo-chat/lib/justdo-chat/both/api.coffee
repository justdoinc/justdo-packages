_.extend JustdoChat.prototype,
  getChannelsSchema: -> JustdoChat.schemas.ChannelsSchema._schema

  getMessagesSchema: -> JustdoChat.schemas.MessagesSchema._schema

  requireAllowedChannelType: (channel_type) ->
    if channel_type not in share.channel_types
      throw @_error "unknown-channel-type", "Unknown channel type #{channel_type}"

    return

  friendlyDateFormat: (date) ->
    moment_date = moment(date)

    if moment_date.isSame(Date.now(), "day")
      # Show hour only
      return moment_date.format("HH:mm")
    else if moment().diff(date, 'days') <= 5 # Last 5 days
      # Show day name and hour
      return moment_date.format("dddd HH:mm")
    else if moment_date.isSame(Date.now(), "year")
      # Show date without year + hour
      return moment_date.format("MMMM Do, HH:mm")
    else
      # Show date with year + hour
      return moment_date.format("MMMM Do YYYY, HH:mm")
    
    return

  requireUserProvided: (user_id) ->
    if not user_id?
      throw @_error "login-required"

    check(user_id, String)

    return true