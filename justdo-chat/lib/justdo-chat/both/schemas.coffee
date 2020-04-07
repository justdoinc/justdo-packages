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

  iv_unread:
    # Read more about this field under README-notification-system.md

    # Is set to the date in which the current unread state turned true as a result of involuntary
    # operation by another member.
    #
    # $unset when unread state turns false for any reason.
    label: "Involuntary Unread"

    optional: true

    type: Date

  iv_unread_type:
    # Read more about this field under README-notification-system.md

    # When iv_unread is set, this field will be set as well with the cause that made this channel
    # unread involuntarily for the subscriber.
    #
    # $unset when unread state turns false for any reason.
    label: "Involuntary Unread Type"

    type: String

    optional: true

    allowedValues: ["new-sub", "new-msg"]

  unread_email_processed:
    # Read more about this field under README-notification-system.md

    # Processed doesn't mean sent, just that we checked whether notification sending is required
    # or not.

    label: "Email unread notifications processed"

    type: Boolean

    optional: true

  unread_firebase_mobile_processed:
    # Read more about this field under README-notification-system.md

    # Processed doesn't mean sent, just that we checked whether notification sending is required
    # or not.

    label: "Firebase mobile push notifications processed"

    type: Boolean

    optional: true

#
# BottomWindowSchema
#
JustdoChat.schemas.BottomWindowSchema = new SimpleSchema
  user_id:
    label: "User ID"

    type: String

  state:
    label: "Window State"

    type: String

    allowedValues: ["min", "open"]

    defaultValue: "open"

  order:
    label: "Order"

    type: Number

    defaultValue: 0

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

  archived_subscribers:
    # In situations where a channel becomes obsolete*, we might want to maintain the history
    # of its subscribers to allow bringing them back for case the procedure that got the channel
    # obsolete got reversed** , the archived_subscribers field serves that purpose .

    # * e.g. for a task channel, situations where the channel's task is remvoed, or the entire
    # project the task belongs to is removed.
    # ** Removed project/task been unremoved

    type: [JustdoChat.schemas.SubscribedUserSchema]

    optional: true

  bottom_windows:
    # Maintains information about users that has an open window with that channel.
    #
    # Unlike subscribers, in case that a channel becomes obsolete, we simply remove
    # this field so we don't maintain archived_bottom_windows .
    type: [JustdoChat.schemas.BottomWindowSchema]

    defaultValue: []

    optional: true

  createdAt:
    label: "Created At"

    type: Date

    optional: true # We must set createdAt to optional (we never do so in other schemas) here because of the complex building of this doc on @getChannelDocNonReactive() (channel-base-server.coffee)

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

    optional: true

    type: String

    min: 1
    max: 10000

  "data_msg_type":
    label: "Data Message type"

    optional: true

    type: String

  "data":
    label: "Data object"

    optional: true

    type: Object

    blackbox: true

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

#
# TasksSchema
#
JustdoChat.schemas.TasksSchema = new SimpleSchema
  "#{JustdoChat.tasks_chat_channel_last_message_from_field_id}":
    label: "Last message from"

    optional: true

    type: String

    autoValue: ->
      # Don't allow the client to edit this field
      if not @isFromTrustedCode
        return @unset()

      return

    grid_dependent_fields: ["title"]

  "#{JustdoChat.tasks_chat_channel_last_message_date_field_id}":
    label: "Last message date"

    optional: true

    type: Date

    autoValue: ->
      # Don't allow the client to edit this field
      if not @isFromTrustedCode
        return @unset()

      return

    grid_dependent_fields: ["title"]

  "#{JustdoChat.tasks_chat_channel_last_read_field_id}":
    label: "Last read date"

    type: Date

    optional: true

    grid_dependent_fields: ["title"]

_.extend JustdoChat.prototype,
  _attachCollectionsSchemas: ->
    @_attachTasksCollectionSchema()
    @_attachChannelsCollectionSchema()
    @_attachMessagesCollectionSchema()

  _attachTasksCollectionSchema: ->
    @tasks_collection.attachSchema JustdoChat.schemas.TasksSchema

    return

  _attachChannelsCollectionSchema: ->
    @channels_collection.attachSchema JustdoChat.schemas.ChannelsSchema

    @_attachChannelsCollectionSchemaChannelsSpecialFields()

    return

  _attachChannelsCollectionSchemaChannelsSpecialFields: ->
    for channel_type, channel_conf of share.channel_types_conf
      if (identifier_fields_simple_schema = channel_conf.channel_identifier_fields_simple_schema)?
        @channels_collection.attachSchema identifier_fields_simple_schema, {selector: {channel_type: channel_type}}

      if (augmented_fields_simple_schema = channel_conf.channel_augmented_fields_simple_schema)?
        @channels_collection.attachSchema augmented_fields_simple_schema, {selector: {channel_type: channel_type}}

    return

  _attachMessagesCollectionSchema: ->
    @messages_collection.attachSchema JustdoChat.schemas.MessagesSchema

    return

