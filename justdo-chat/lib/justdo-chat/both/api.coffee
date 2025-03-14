_.extend JustdoChat.prototype,
  _bothImmediateInit: ->
    # @_bothImmediateInit runs before the specific env's @_immediateInit()

    # Add here code that should run, in the Server and Client, during the JS
    # tick in which we create the object instance.

    @_getTypeIdentifiyingFields_cached_result = {}
    @_getTypeAugmentedFields_cached_result = {}

    return

  _bothDeferredInit: ->
    # @_bothDeferredInit runs before the specific env's @_deferredInit()

    # Add here code that should run, in the Server and Client, after the JS
    # tick in which we created the object instance.

    if @destroyed
      return

    return

  getChannelsSchema: -> JustdoChat.schemas.ChannelsSchema._schema

  getMessagesSchema: -> JustdoChat.schemas.MessagesSchema._schema

  requireAllowedChannelType: (channel_type) ->
    if channel_type not in share.channel_types
      throw @_error "unknown-channel-type", "Unknown channel type #{channel_type}"

    return

  requireUserProvided: (user_id) ->
    if not user_id?
      throw @_error "login-required"

    check(user_id, String)

    return true

  # The result shouldn't change during the instance lifetime, so we can cache it
  _getTypeIdentifiyingFields_cached_result: null # initiated to {} on @_immediateInit()
  getTypeIdentifiyingFields: (type) ->
    if (identifying_fields = @_getTypeIdentifiyingFields_cached_result[type])?
      return identifying_fields

    identifying_fields = share.channel_types_conf[type].channel_identifier_fields_simple_schema._schemaKeys
    # Replace all occurances of ".$" or ".$.subfield" since they are illegal in MongoDB 4.4 (Read the comment in static-settings.coffee about positional_operator_regex for more info)
    # Example:
    #   channel_identifier_fields_simple_schema: new SimpleSchema
    #     user_ids:
    #       type: [String]
    #       minCount: 2
    #       maxCount: 2
    # Will result in identifying_fields=["user_ids", "user_ids.$"]
    # But we 
    #  1. actually only need user_ids,
    #  2. can't use user_ids and user_ids.$ together
    identifying_fields = _.filter identifying_fields, (field_id) -> not JustdoChat.positional_operator_regex.test field_id

    @_getTypeIdentifiyingFields_cached_result[type] = identifying_fields

    return identifying_fields

  # The result shouldn't change during the instance lifetime, so we can cache it
  _getTypeAugmentedFields_cached_result: null # initiated to {} on @_immediateInit()
  getTypeAugmentedFields: (type) ->
    if (augmented_fields = @_getTypeAugmentedFields_cached_result[type])?
      return augmented_fields

    augmented_fields = share.channel_types_conf[type].channel_augmented_fields_simple_schema._schemaKeys
    # Replace all occurances of ".$" or ".$.subfield" since they are illegal in MongoDB 4.4 (Read the comment in static-settings.coffee about positional_operator_regex for more info)
    # Scroll above in side comment of getTypeIdentifiyingFields for example
    augmented_fields = _.filter augmented_fields, (field_id) -> not JustdoChat.positional_operator_regex.test field_id

    @_getTypeAugmentedFields_cached_result[type] = augmented_fields

    return augmented_fields

  getTypeIdentifiyingAndAugmentedFields: (type) ->
    return @getTypeIdentifiyingFields(type).concat(@getTypeAugmentedFields(type))

  # The result shouldn't change during the instance lifetime, so we can cache it
  _getAllTypesIdentifiyingAndAugmentedFields_cached_result: null
  getAllTypesIdentifiyingAndAugmentedFields: ->
    if @_allTypesIdentifiyingAndAugmentedFields_cached_result?
      return @_allTypesIdentifiyingAndAugmentedFields_cached_result

    result = []
    for channel_type, channel_type_conf of share.channel_types_conf
      result = result.concat @getTypeIdentifiyingAndAugmentedFields(channel_type)

    @_allTypesIdentifiyingAndAugmentedFields_cached_result = result

    return @_allTypesIdentifiyingAndAugmentedFields_cached_result

  isBotUserId: (user_id) ->
    if user_id.substr(0, JustdoChat.bot_user_id_prefix.length) == JustdoChat.bot_user_id_prefix
      return true

    return false
