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

      @channels_collection.rawCollection().createIndex(channel_identifier_index_definition_obj, index_options)

    #
    # Ensure messages fetching indexes
    #
    @messages_collection.rawCollection().createIndex({channel_id: 1, createdAt: -1})

    return