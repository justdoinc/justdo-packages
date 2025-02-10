JustdoChat.registerChannelType
  channel_type: "group" # Must be dash-separated! should be == @channel_type in client/server constructor
  channel_type_camel_case: "Group" # Should be the same as the camel case form used in the client/server constructors names

  # Read about the identifier fields on the comment for @getChannelIdentifier() under channel-base-client.coffee
  # The information there is comprehensive and essential to understand the purpose and use of that definition!
  channel_identifier_fields_simple_schema: new SimpleSchema 
    _id: 
      type: String
    project_id:
      type: String
      optional: true

  # Read about the identifier fields on the comment for @getChannelAugmentedFields() under channel-base-server.coffee
  # The information there is comprehensive and essential to understand the purpose and use of that definition!
  channel_augmented_fields_simple_schema: new SimpleSchema 
    title:
      label: "Title"
      type: String
    description:
      label: "Description"
      type: String
      optional: true
    group_icon:
      label: "Group icon"
      type: String
      optional: true
    admins:
      label: "Admins"
      type: [Object]
    "admins.$.user_id":
      type: String
    "admins.$.appointed_at":
      type: Date
    "admins.$.appointed_by":
      type: String
  # Add augmented field indexes to the channel collection
  # Note that channel_augmented_fields_indexes should hold an array of index declearations
  channel_augmented_fields_indexes: [
    {
      "admins.user_id": 1
    }
  ]

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
  recent_activity_supplementary_pseudo_collections: {}

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
  bottom_windows_supplementary_pseudo_collections: {}    