# Note the constructor below extends the ChannelBaseServer constructor
ChannelBaseServer = share.ChannelBaseServer

channel_conf = JustdoChat.getChannelTypeConf("user")

{channel_type, channel_identifier_fields_simple_schema} = channel_conf

# Name should follow task-channel-both-registrar.coffee : channel_type_camel_case + "ChannelServer"
UserChannelServer = (options) ->
  ChannelBaseServer.call this, options

  return @

Util.inherits UserChannelServer, ChannelBaseServer

_.extend UserChannelServer.prototype,
  _errors_types: _.extend {}, ChannelBaseServer.prototype._errors_types, {}

  channel_type: channel_type

  channel_name_dash_separated: "#{channel_type}-channel-server" # for logging purposes

  channel_identifier_schema: channel_identifier_fields_simple_schema
  _superVerifyChannelIdentifierObjectAgainstSchema: ChannelBaseServer.prototype._verifyChannelIdentifierObjectAgainstSchema
  _verifyChannelIdentifierObjectAgainstSchema: ->
    # Ensure user_ids are sorted
    @channel_identifier?.user_ids = _.sortBy @channel_identifier?.user_ids

    return @_superVerifyChannelIdentifierObjectAgainstSchema()

  loadChannel: ->
    if @getChannelDocCursor().count() is 0
      @manageSubscribers {add: @channel_identifier.user_ids}
    return

  isValidChannelIdentifier: ->
    if (not _.isArray @channel_identifier?.user_ids) or (_.size @channel_identifier.user_ids) isnt 2
      return false
    
    if @channel_identifier.user_ids[0] is @channel_identifier.user_ids[1]
      return false

    if @performing_user not in @channel_identifier.user_ids
      return false

    return true

  _getUsersAccessPermission: (users_ids) ->
    result_array = {
      permitted: []
      not_permitted: []
    }

    # Allow anyone to create a new channel
    if @getChannelDocCursor().count() is 0
      result_array.permitted = users_ids
      return result_array

    channel_doc = @getChannelDocNonReactive()

    for user_id in users_ids
      if @justdo_chat.isBotUserId user_id
        result_array.permitted.push user_id
      else if _.find channel_doc?.user_ids, (channel_user_id) -> channel_user_id is user_id
        result_array.permitted.push user_id
      else
        result_array.not_permitted.push user_id

    return result_array

  getCounterpartUser: (fields) ->
    if not fields?
      fields = 
        profile: 1

    counterpart_user_id = _.without(@channel_identifier.user_ids, @performing_user)[0]

    return Meteor.users.findOne(counterpart_user_id, {fields})

share.UserChannelServer = UserChannelServer

_.extend JustdoChat.prototype, 
  _generateServerUserChatChannelOptionsSchema: new SimpleSchema
    open_bottom_window:
      type: Boolean
      optional: true
      defaultValue: true
  generateServerUserChatChannel: (user_ids, options={}) ->
    {cleaned_val} = 
      JustdoHelpers.simpleSchemaCleanAndValidate(
        @_generateServerUserChatChannelOptionsSchema,
        options,
        {self: @, throw_on_error: true}
      )
    options = cleaned_val

    channel = @generateServerChannel "user", {user_ids}, options

    if options.open_bottom_window
      channel.makeWindowVisible()
    
    return channel