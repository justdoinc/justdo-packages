_.extend JustdoChat.prototype,
  # In the past, we setup unique indexes for all keys in channel_identifier_index_definition_obj,
  # provided that the only channel type is "task" and the index added was "task_id_1".
  # With the introduction of new channel types, there's no "task_id" in document, that it'll break insertions if "unique" is set to true.
  _dropUniqueIndexes: ->
    raw_channels_collection = @channels_collection.rawCollection()
    raw_channels_collection.indexes()
      .then (indexes) =>
        indexes_to_drop = []
        for index in indexes
          if index.unique
            indexes_to_drop.push index.name

        if _.isEmpty indexes_to_drop
          return

        raw_channels_collection.dropIndexes indexes_to_drop
          .then => @logger.info "Dropped unique indexes: #{indexes_to_drop}"
          .catch (err) => @logger.error "Unable to drop unique indexes #{indexes_to_drop}. Error: #{err}"
        return
      .catch (err) => @logger.error err
    return

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

      index_options = {}
      # CHANNEL_IDENTIFIER_INDEX
      @channels_collection.rawCollection().createIndex(channel_identifier_index_definition_obj, index_options)

    # For channel types that requested it in their config, add index for their
    # augmented fields.
    for channel_type, channel_type_conf of share.channel_types_conf
      if not channel_type_conf.add_index_for_augmented_fields
        continue

      #
      # Ensure channel identifier fields index for each one of the channel type identifiers
      #
      channel_augmented_keys =
        channel_type_conf.channel_augmented_fields_simple_schema._schemaKeys

      channel_augmented_fields_definition_obj = {}

      for key in channel_augmented_keys
        channel_augmented_fields_definition_obj[key] = 1

      # CHANNEL_AUGMENTED_FIELDS_INDEX
      @channels_collection.rawCollection().createIndex(channel_augmented_fields_definition_obj)

    # MESSAGES_FETCHING_INDEX
    @messages_collection.rawCollection().createIndex({channel_id: 1, createdAt: -1})

    # USER_UNREAD_MESSAGES_INDEX
    @channels_collection.rawCollection().createIndex({"subscribers.user_id": 1, "subscribers.unread": 1})

    # USER_BOTTOM_WINDOWS_INDEX
    @channels_collection.rawCollection().createIndex({"bottom_windows.user_id": 1, "bottom_windows.order": 1})

    # INVOLUNTARY_UNREAD_NOTIFICATIONS_HANDLING_CRITERIA
    @channels_collection.rawCollection().createIndex({"subscribers.iv_unread": 1, "subscribers.unread_email_processed ": 1})
    @channels_collection.rawCollection().createIndex({"subscribers.iv_unread": 1, "subscribers.unread_firebase_mobile_processed ": 1})

    return