# JustdoChat.schemas / share.channel_types initiated on static-channel-registrar.coffee

JustdoChat.schemas = {}

#
# SubscribedUserSchema
#
JustdoChat.schemas.SubscribedUserSchema = new SimpleSchema
  user_id:
    label: "User ID"

    type: String

  unread:
    label: "Has Unread Messages"

    type: Boolean

  last_read:
    label: "Last Read"

    optional: true

    type: Date

  # web_window_state:
  #   type: String

  #   optional: true

  #   allowedValues: ["open", "minified", "closed"]

#
# ChannelsSchema
#
JustdoChat.schemas.ChannelsSchema = new SimpleSchema
  channel_type:
    label: "Channel type"

    type: String

    allowedValues: share.channel_types

    defaultValue: "task"

  last_message_date:
    label: "Last message"

    type: Date

    optional: true

  messages_count:
    label: "Messages count"

    type: Number

    defaultValue: 0

    optional: true

  subscribers:
    type: [JustdoChat.schemas.SubscribedUserSchema]

    defaultValue: []

    optional: true

  createdAt:
    label: "Created At"

    type: Date

    optional: true # We must set createdAt to optional (we never do so in other schemas) here because of the complex building of this doc on @getChannelDoc() (channel-base-server.coffee)

    autoValue: ->
      if this.isInsert
        return new Date()
      else if this.isUpsert
        return {$setOnInsert: new Date()}
      else
        @unset()

  # I think that due to the management of the subscribed users and their states
  # on this doc, the updatedAt is quite redundant. -Daniel C.

  # updatedAt:
  #   label: "Updated At"

  #   type: Date

  #   autoValue: ->
  #     if this.isUpdate
  #       return new Date()
  #     else if this.isInsert
  #       return new Date()
  #     else if this.isUpsert
  #       return {$setOnInsert: new Date()}
  #     else
  #       @unset()

#
# MessagesSchema
#
JustdoChat.schemas.MessagesSchema = new SimpleSchema
  channel_id:
    label: "Channel ID"

    type: String

  channel_type:
    label: "Channel Type" # Not normalized, this information can be retreived from the channel_id, but we keep it for structure (see below type specific special fields), and queries efficiency.

    type: String

    allowedValues: share.channel_types

    defaultValue: "task"

  body:
    label: "Message body"

    type: String

    min: 1
    max: 10000

  author:
    label: "Message author"

    type: String

  createdAt:
    label: "Created At"

    type: Date

    autoValue: ->
      if this.isInsert
        return new Date()
      else if this.isUpsert
        return {$setOnInsert: new Date()}
      else
        @unset()

  # Not sure if updatedAt necessary at the moment -Daniel C.
  # updatedAt:
  #   label: "Updated At"

  #   type: Date

  #   autoValue: ->
  #     if this.isUpdate
  #       return new Date()
  #     else if this.isInsert
  #       return new Date()
  #     else if this.isUpsert
  #       return {$setOnInsert: new Date()}
  #     else
  #       @unset()

_.extend JustdoChat.prototype,
  _attachCollectionsSchemas: ->
    @_attachChannelsCollectionSchema()
    @_attachMessagesCollectionSchema()

  _attachChannelsCollectionSchema: ->
    @channels_collection.attachSchema JustdoChat.schemas.ChannelsSchema

    @_attachChannelsCollectionSchemaChannelsSpecialFields()

    return

  _attachChannelsCollectionSchemaChannelsSpecialFields: ->
    for channel_type, channel_conf of share.channel_types_conf
      if (identifier_fields_simple_schema = channel_conf.channel_identifier_fields_simple_schema)?
        @channels_collection.attachSchema identifier_fields_simple_schema, {selector: {channel_type: channel_type}}

      if (augemented_fields_simple_schema = channel_conf.channel_augemented_fields_simple_schema)?
        @channels_collection.attachSchema augemented_fields_simple_schema, {selector: {channel_type: channel_type}}

    return

  _attachMessagesCollectionSchema: ->
    @messages_collection.attachSchema JustdoChat.schemas.MessagesSchema

    return

