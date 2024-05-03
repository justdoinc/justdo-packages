JustdoChat.registerChannelType
  channel_type: "user" # Must be dash-separated! should be == @channel_type in client/server constructor
  channel_type_camel_case: "User" # Should be the same as the camel case form used in the client/server constructors names

  # Read about the identifier fields on the comment for @getChannelIdentifier() under channel-base-client.coffee
  # The information there is comprehensive and essential to understand the purpose and use of that definition!
  channel_identifier_fields_simple_schema: new SimpleSchema
    user_ids:
      type: [String]
      minCount: 2
      maxCount: 2

  # Read about the identifier fields on the comment for @getChannelAugmentedFields() under channel-base-server.coffee
  # The information there is comprehensive and essential to understand the purpose and use of that definition!
  channel_augmented_fields_simple_schema: new SimpleSchema()
  # If set to true, an mongodb index will be added with all the keys specified under
  # channel_augmented_fields_simple_schema see collections-indexes.coffee
  add_index_for_augmented_fields: false

  # Read comment for publication jdcSubscribedChannelsRecentActivity under publications.coffee
  # to learn about recent_activity_supplementary_pseudo_collections purpose.
  #
  # Collections should be defined as follows:
  #
  # {col_id: "CollectionName"}
  #
  # The provided 'CollectionName's will be prefixed by us with JDChatRecentActivity
  # and will have that name when accessed through the correct APIs.
  #
  # Once JustdoChat is initiated on the client side, a pseudo collections will be created under:
  # justdo_chat_object.recent_activity_supplementary_pseudo_collections.col_id <- That will be a minimongo
  # object.
  #
  # Access by calling the static method: JustdoChat.getChannelTypeConf(channel_type)
  recent_activity_supplementary_pseudo_collections:
    users: "Users"

  # Read comment for publication jdcBottomWindows under publications.coffee
  # to learn about bottom_windows_supplementary_pseudo_collections purpose.
  #
  # Collections should be defined as follows:
  #
  # {col_id: "CollectionName"}
  #
  # The provided 'CollectionName's will be prefixed by us with JDChatBottomWindows
  # and will have that name when accessed through the correct APIs.
  #
  # Once JustdoChat is initiated on the client side, a pseudo collections will be created under:
  # justdo_chat_object.bottom_windows_supplementary_pseudo_collections.col_id <- That will be a minimongo
  # object.
  #
  # Access by calling the static method: JustdoChat.getChannelTypeConf(channel_type)
  bottom_windows_supplementary_pseudo_collections:
    users: "Users"
