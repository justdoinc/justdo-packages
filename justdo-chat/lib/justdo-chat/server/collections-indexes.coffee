_.extend JustdoChat.prototype,
  _ensureIndexesExists: ->
    for channel_type, channel_type_conf of share.channel_types_conf
      #
      # Ensure channel identifier fields index for each one of the channel type identifiers
      #
      channel_identifier_keys =
        channel_type_conf.channel_identifier_fields_simple_schema._schemaKeys

      channel_identifier_index_definition_obj = {}

      for key in channel_identifier_keys
        channel_identifier_index_definition_obj[key] = 1

      index_options =
        unique: true

      # CHANNEL_IDENTIFIER_INDEX
      @channels_collection.rawCollection().createIndex(channel_identifier_index_definition_obj, index_options)

    # For channel types that requested it in their config, add index for their
    # augmented fields.
    for channel_type, channel_type_conf of share.channel_types_conf
      if not channel_type_conf.add_index_for_augemented_fields
        continue

      #
      # Ensure channel identifier fields index for each one of the channel type identifiers
      #
      channel_augemented_keys =
        channel_type_conf.channel_augemented_fields_simple_schema._schemaKeys

      channel_augmented_fields_definition_obj = {}

      for key in channel_augemented_keys
        channel_augmented_fields_definition_obj[key] = 1

      # CHANNEL_AUGMENTED_FIELDS_INDEX
      @channels_collection.rawCollection().createIndex(channel_augmented_fields_definition_obj)

    # MESSAGES_FETCHING_INDEX
    @messages_collection.rawCollection().createIndex({channel_id: 1, createdAt: -1})

    # USER_UNREAD_MESSAGES_INDEX
    @channels_collection.rawCollection().createIndex({"subscribers.user_id": 1, "subscribers.unread": 1})

    return