# Note the constructor below extends the ChannelBaseClient constructor
ChannelBaseClient = share.ChannelBaseClient

channel_conf = JustdoChat.getChannelTypeConf("user")

{channel_type} = channel_conf

# Name should follow task-channel-both-register.coffee : channel_type_camel_case + "ChannelClient"
UserChannelClient = (options) ->
  ChannelBaseClient.call this, options

  return @

Util.inherits UserChannelClient, ChannelBaseClient

_.extend UserChannelClient.prototype,
  _errors_types: _.extend {}, ChannelBaseClient.prototype._errors_types, {}

  channel_type: channel_type

  channel_name_dash_separated: "#{channel_type}-channel-client" # for logging purposes

  channel_conf_schema: new SimpleSchema
    user_ids:
      type: [String]

  getChannelIdentifier: ->
    return @channel_conf

  loadChannel: ->
    # Ensure user_ids are sorted
    @channel_conf.user_ids = _.sortBy @channel_conf.user_ids

    if @channel_conf.user_ids[0] is @channel_conf.user_ids[1]
      throw @_error "invalid-argument"
    
    if Meteor.userId() not in @channel_conf.user_ids
      throw @_error "permission-denied"
    return

  getMessagesSubscriptionChannelDoc: (query_options) ->
    return @_getChannelsCollection().findOne(@getChannelIdentifier(), query_options)

share.UserChannelClient = UserChannelClient

_.extend JustdoChat.prototype,
  _generateClientUserChatChannelOptionsSchema: new SimpleSchema
    open_bottom_window:
      type: Boolean
      optional: true
      defaultValue: true
  generateClientUserChatChannel: (user_id, options={}) ->
    {cleaned_val} = 
      JustdoHelpers.simpleSchemaCleanAndValidate(
        @_generateClientUserChatChannelOptionsSchema,
        options,
        {self: @, throw_on_error: true}
      )
    options = cleaned_val
  
    channel = @generateClientChannelObject "user", {user_ids: [Meteor.userId(), user_id]}, options

    if options.open_bottom_window
      channel.makeWindowVisible()
    
    return channel