ChannelBaseServer = (options) ->
  # derived from skeleton-version: v0.0.11-onepage_skeleton

  EventEmitter.call this

  @destroyed = false

  @logger = Logger.get(@channel_name_dash_separated)
  @JA = JustdoAnalytics.setupConstructorJA(@, @channel_name_dash_separated)

  # @logger.debug "Init begin" - too many inits to log

  @options = _.extend {}, @default_options, options
  if not _.isEmpty(@options_schema)
    # If @options_schema is set, use it to apply strict structure on
    # @options.
    #
    # Clean and validate @options according to @options_schema.
    # invalid-options error will be thrown for invalid options.
    # Takes care of binding options with bind_to_instance to
    # the instance.
    @options =
      JustdoHelpers.loadOptionsWithSchema(
        @options_schema, @options, {
          self: @
          additional_schema: # Adds the `events' option to the permitted fields
            events:
              type: Object
              blackbox: true
              optional: true
        }
      )

  JustdoHelpers.loadEventEmitterHelperMethods(@)
  @loadEventsFromOptions() # loads @options.events, if exists

  @_on_destroy_procedures = []

  @_immediateInit()

  Meteor.defer =>
    @_deferredInit()

  # @logger.debug "Init done" - too many inits to log

  return @

Util.inherits ChannelBaseServer, EventEmitter

_.extend ChannelBaseServer.prototype,
  #
  # The following SHOULDN'T change by the inheriting channels constructors
  #
  _error: JustdoHelpers.constructor_error

  default_options: {}

  options_schema:
    both:
      justdo_chat:
        type: "skip-type-check"
        optional: false
        bind_to_instance: true

      channel_identifier:
        type: Object
        optional: false
        blackbox: true
        bind_to_instance: true

      performing_user:
        type: String
        optional: false
        bind_to_instance: true
        min: 1

    _processedNotificationsIndicatorsFields: ["unread_email_processed", "unread_firebase_mobile_processed"]
    # Read more about Processed Notifications Indicators Fields under README-notification-system.md

  _immediateInit: ->
    @_verifyChannelIdentifierObjectAgainstSchema()

    @requireValidChannelIdentifier()
    @requirePerformingUserPermittedToAccessChannel()

    @loadChannel()

    return

  _deferredInit: ->
    if @destroyed
      return

    return

  onDestroy: (proc) ->
    @_on_destroy_procedures.push proc

    return

  destroy: ->
    if @destroyed
      @logger.debug "Destroyed already"

      return

    _.each @_on_destroy_procedures, (proc) -> proc()

    @destroyed = true

    @logger.debug "Destroyed"

    return

  replacePerformingUser: (user_id) ->
    # Set @performing_user to user_id, and ensure it has access to the channel.
    # throws an error otherwise, reversing the @performing_user to the previous
    # one.

    original_performing_user = @performing_user

    @performing_user = user_id

    try
      @requirePerformingUserPermittedToAccessChannel()
    catch e
      @performing_user = original_performing_user

      throw e

    return

  getChannelTypeIdentifiyingFields: ->
    return @justdo_chat.getTypeIdentifiyingFields(@channel_type)

  getChannelTypeAugmentedFields: ->
    return @justdo_chat.getTypeAugmentedFields(@channel_type)

  getChannelTypeIdentifiyingAndAugmentedFields: ->
    return @justdo_chat.getTypeIdentifiyingAndAugmentedFields(@channel_type)

  _verifyChannelIdentifierObjectAgainstSchema: ->
    {cleaned_val} =
      JustdoHelpers.simpleSchemaCleanAndValidate(
        @channel_identifier_schema,
        @channel_identifier,
        {self: @, throw_on_error: true}
      )
    @channel_identifier = cleaned_val

    return

  requireValidChannelIdentifier: ->
    if not @isValidChannelIdentifier()
      throw @_error "invalid-channel" # read comment in @_errors_types where this error defined. 

    return

  getUsersAccessPermission: (users_ids) ->
    if not users_ids?
      throw @_error "invalid-argument", "No users ids provided"

    if _.isString(users_ids) and not _.isEmpty(users_ids)
      users_ids = [users_ids]

    if _.isArray users_ids # We don't rely on the input type still.
      users_ids = _.compact(users_ids) # Remove null/undefined values

    if not _.isArray(users_ids) or _.isEmpty(users_ids)
      # Note, it is very important to throw an exception here.
      # @_getUsersAccessPermission() expect users_ids to be non-empty.
      #
      # If it is empty, it'll return an empty not_permitted array, which can be interpreted
      # as - all users has access, which in return is a major security issue.
      #
      # Don't remove this exception without serious thought about implications.
      throw @_error "invalid-argument", "Users ids must be a non-empty string, or a non empty array"

    check users_ids, [String]

    return @_getUsersAccessPermission(users_ids)

  removeNonPermittedUsers: (users_ids) ->
    # Gets users_ids array and returns an array that includes only the users that are permitted
    # to access the channel.

    if _.isEmpty(users_ids)
      return []

    return @getUsersAccessPermission(users_ids).permitted

  areUsersPermittedToAccess: (users_ids) ->
    return @getUsersAccessPermission(users_ids).not_permitted.length == 0

  requirePerformingUserPermittedToAccessChannel: ->
    if not @areUsersPermittedToAccess(@performing_user)
      throw @_error "invalid-channel" # read why we don't use the access-forbidden error in the comment in @_errors_types where this error defined.

    return

  requireUsersPermittedToAccess: (users_ids) ->
    if not @areUsersPermittedToAccess(users_ids)
      throw @_error "access-forbidden", "Some users listed aren't permitted to access this channel"

    return

  @_cached_channel_doc = null
  _getCachedChannelDoc: (allow_cache=true) ->
    # The allow_cache arg, which seem weird, is a kind of "syntactic sugar"

    if allow_cache and @_cached_channel_doc?
      return @_cached_channel_doc

    return undefined
  findAndModifyChannelDoc: (conf) ->
    # Important findAndModify is not going through simple schema!
    #
    # We cache the returned channel modified doc value to avoid subsequent calls to the db,
    # to which getting as up-to-date doc as possible is not critical. The cached doc is stored
    # under @_cached_channel_doc.
    #
    default_conf = {upsert: false}
    
    conf = _.extend {}, default_conf, conf

    {update, upsert} = conf

    if not update?
      @logger.info "@findAndModifyChannelDoc: conf.update not provided"

      return

    #
    # IMPORTANT, if you change the following, don't forget to update the collections-indexes.coffee
    # and to drop obsolete indexes (see CHANNEL_IDENTIFIER_INDEX there)
    #
    result = @justdo_chat.channels_collection.findAndModify
      query: @channel_identifier,
      update: update
      upsert: upsert
      new: true # return the doc after the modification

    if result.ok != 1
      throw @_error "db-error", "Unknown database error when trying to create channel"

    @_cached_channel_doc = result.value

    return result.value

  getChannelDocNonReactive: (allow_cache=true) ->
    # Retrieves the channel doc for the identifier. Creates one if one doesn't exists.

    # We add the NonReactive suffix to make it clear that we don't return cursor here,
    # to avoid mistakes by future developers that might return the output of this method
    # in a publication (of course, there is no reactivity in the server. D.C ).

    # Caching:
    #
    # We try to obtain the cached doc using @_getCachedChannelDoc().
    # If you want to force retrival from the db, even if cached doc available already, call with
    # allow_cache=false (the value retrieved will replace the existing @_cached_channel_doc)
    #
    # Retreiving/creating the channel doc in one call:
    #
    # We want a single call to the db to either give us the existing channel doc, or insert one and
    # provide us the inserted channel doc + _id, if one doesn't exist already.
    #
    # In the following few lines we are going to build the channel init doc, to be used only if doc for
    # the channel doesn't exist already.
    #

    # No reliance on the collection2 package
    #
    # Using findAndModify and $setOnInsert for efficiency, turned out to be way too complex for collection2 to handle.
    # Therefore, we need to build the channel document without relying on auto value and cleanups and validations performed
    # by collection2.
    #

    if (channel_doc = @_getCachedChannelDoc(allow_cache))?
      return channel_doc

    # Generate the base document, based on the default values of the ChannelsSchema
    {cleaned_val} =
      JustdoHelpers.simpleSchemaCleanAndValidate(
        JustdoChat.schemas.ChannelsSchema,
        {
          channel_type: @channel_type
        },
        {self: @, throw_on_error: true}
      )
    channel_document = cleaned_val

    # Add the createdAt
    channel_document.createdAt = new Date()

    # Get the channel augmented fields
    # We assume @getChannelAugmentedFields() complies with the channel conf channel_augmented_fields_simple_schema
    channel_augmented_fields = @getChannelAugmentedFields() 

    # Add the channel identifier and augmented fields
    channel_document = _.extend(channel_document,
      @channel_identifier,
      channel_augmented_fields
    )

    channel_doc = @findAndModifyChannelDoc
      upsert: true
      update: {$setOnInsert: channel_document}

    return channel_doc

  _setBottomWindowWindowSettingsObjectSchema: new SimpleSchema
    order:
      type: Number

      optional: true

    state:
      # If any of the provided users isn't subscribed, we just ignore it

      type: String

      allowedValues: JustdoChat.schemas.BottomWindowSchema._schema.state.allowedValues

      optional: true

  setBottomWindow: (window_settings) ->
    # Creates/updates a window for this channel for performing user.
    #
    # If window_settings is empty, we ignore the request, we throw error, to ease tracking the issue.

    if not window_settings?
      throw @_error "invalid-argument", "setBottomWindow: you must provide non-empty window_settings"

    {cleaned_val} =
      JustdoHelpers.simpleSchemaCleanAndValidate(
        @_setBottomWindowWindowSettingsObjectSchema,
        window_settings,
        {self: @, throw_on_error: true}
      )
    window_settings = cleaned_val

    if _.isEmpty(window_settings)
      throw @_error "invalid-argument", "setBottomWindow: you must provide non-empty window_settings"

 
    # XXX Index wise, it seems that since @channel_identifier is involved in the query, mongo,
    # is capable to use the CHANNEL_IDENTIFIER_INDEX to optimize this query,
    # at the moment, no further indexes are added for this one Daniel C.

    #
    # First, assume that an entry for a bottom window for the performing user exists already
    # for that channel, and update it with the new window_settings.
    #
    # If we get nModified == 0, it means, that an entry didn't exist, in such a case we push
    # a new entry.
    #
    update_existing_bottom_window_query = _.extend {}, @channel_identifier,
      bottom_windows:
        $elemMatch:
          user_id: @performing_user

    fields_to_set = {}
    for field, val of window_settings
      fields_to_set["bottom_windows.$.#{field}"] = val
    update_existing_bottom_window_query_update =
      $set: fields_to_set

    @justdo_chat.channels_collection.rawCollection().update update_existing_bottom_window_query, update_existing_bottom_window_query_update, Meteor.bindEnvironment (err, res) =>
      # XXX API might change to nMatched on future Mongo versions
      if res.result.n != 0
        # Update performed, nothing further to do.

        return

      @getChannelDocNonReactive() # to create the channel document, for case it doesn't exist

      # The first clean, didn't apply defaults, in case of updates, we don't want to update
      # fields the user didn't request a change for. But, when creating a new bottom_window
      # entry for this channel for the performing user, we want to apply the defaults.

      window_settings.user_id = @performing_user # Reminder, the process of window_settings cleaning, performs shallow copy.

      {cleaned_val} =
        JustdoHelpers.simpleSchemaCleanAndValidate(
          JustdoChat.schemas.BottomWindowSchema,
          window_settings,
          {self: @, throw_on_error: true}
        )
      window_settings = cleaned_val

      @findAndModifyChannelDoc
        update:
          $push:
            bottom_windows: window_settings

      return

    return

  removeBottomWindow: ->
    # Remove the window performing user got with this channel (if such a window exists).

    @findAndModifyChannelDoc
      update:
        $pull:
          bottom_windows:
            user_id: @performing_user

    return

  _manageSubscribersUpdateObjectSchema: new SimpleSchema
    add:
      type: [String]
      # type: [Object]

      defaultValue: []

      optional: true

    remove:
      # If any of the provided users isn't subscribed, we just ignore it

      type: [String]

      defaultValue: []

      optional: true # [user_id_1, user_id_2, ...]

  manageSubscribers: (update) ->
    # update should be of the following structure
    #
    # {
    #   add: [] # users to add
    #   remove: [] # users to remove
    # }
    #
    # IMPORTANT:
    # Added subscribers that are already subscribed are completely ignored.
    # Removed subscribers that aren't subscried are completely ignored.
    #
    # If same user id is in both add and in remove, invalid-argument will be thrown
    #
    # The add array is filtered through the @removeNonPermittedUsers(), we don't worry about the remove array.
    #
    # For added users manageSubscribers will set the unread property of the subscriber object
    # according to the following rules:
    #
    # If added user id is the performing user: unread = false
    # If added user id is not the performing user:
    #   If channel has messages: unread = true
    #   else: unread = false

    if not update? or _.isEmpty(update)
      # Nothing to do
      return

    {cleaned_val} =
      JustdoHelpers.simpleSchemaCleanAndValidate(
        @_manageSubscribersUpdateObjectSchema,
        update,
        {self: @, throw_on_error: true}
      )
    update = cleaned_val

    if _.intersection(update.add, update.remove).length != 0
      throw @_error "invalid-argument", "Can't add and remove same user id"

    # Get rid of user ids of users that are not permitted to subscribe
    update.add = @removeNonPermittedUsers(update.add)

    channel_doc = @getChannelDocNonReactive()

    # Remove already subscribed / already removed
    existing_users = _.map channel_doc.subscribers, (subscribed_user) ->
      return subscribed_user.user_id
    update.add = _.difference update.add, existing_users
    update.remove = _.intersection update.remove, existing_users

    # See if after all that, there's still work to do
    if _.isEmpty(update.add) and _.isEmpty(update.remove)
      # Nothing to do
      return

    # Build query
    add_query_items = []
    for user_id in update.add
      subscriber_obj = {user_id: user_id}

      if not (user_id != @performing_user and channel_doc.messages_count != 0)
        # We turn the unread flag on, only for users that aren't the performing user
        # (which necessarily see this channel), and if there are messages at all
        subscriber_obj.unread = false

        if channel_doc.messages_count != 0
          subscriber_obj.last_read = new Date()
      else
        subscriber_obj.unread = true
        subscriber_obj.iv_unread = new Date()
        subscriber_obj.iv_unread_type = "new-sub"

      add_query_items.push subscriber_obj

    remove_query_items = []
    for user_id in update.remove
      remove_query_items.push user_id

    # Perform the update, note, we can't $pull and $push to same field on same update,
    # hence, two updates
    if not _.isEmpty add_query_items
      query = {}

      query.$push =
        subscribers:
          $each:
            add_query_items

      @findAndModifyChannelDoc
        update: query

    if not _.isEmpty remove_query_items
      query = {}

      query.$pull =
        subscribers:
          user_id:
            $in: remove_query_items

      @findAndModifyChannelDoc
        update: query

    return

  setChannelUnreadState: (unread) ->
    check unread, Boolean

    # XXX Index wise, it seems that since @channel_identifier is involved in the query, mongo,
    # is capable to use the CHANNEL_IDENTIFIER_INDEX to optimize this query,
    # at the moment, no further indexes are added for this one Daniel C.

    query = _.extend {}, @channel_identifier,
      subscribers:
        $elemMatch:
          user_id: @performing_user
          unread: not unread # note we don't find if the user unread state is already the requested one

    update =
      $set:
        "subscribers.$.unread": unread

    if unread == false
      update.$set["subscribers.$.last_read"] = new Date()

      update.$unset = {}

      update.$unset["subscribers.$.iv_unread"] = ""
      update.$unset["subscribers.$.iv_unread_type"] = ""

      for unread_notification_type, unread_notification_conf of share.unread_channels_notifications_conf
        update.$unset["subscribers.$.#{unread_notification_conf.processed_notifications_indicator_field_name}"] = ""

    @justdo_chat.channels_collection.rawCollection().update query, update

    return

  _sendMessageMessageObjectSchemaForTxtType: new SimpleSchema
    body:
      # Note, simple schema takes care of .trim() the value for us

      type: String

      min: JustdoChat.schemas.MessagesSchema._schema.body.min
      max: JustdoChat.schemas.MessagesSchema._schema.body.max
  sendMessage: (message_obj, message_type="txt") ->
    # Message type can be either txt or data

    check message_obj, Object
    check message_type, String

    if message_type == "txt"
      messages_schema = @justdo_chat.getMessagesSchema()
      if message_obj?.body?.length > (max_task_length = messages_schema.body.max)
        # Just to provide a more friendly error message for that case (v.s the one simple schema will throw)
        throw @_error "invalid-message", "Message can't be longer than #{max_task_length} charecters"

      {cleaned_val} =
        JustdoHelpers.simpleSchemaCleanAndValidate(
          @_sendMessageMessageObjectSchemaForTxtType,
          message_obj,
          {self: @, throw_on_error: true}
        )
      message_obj = cleaned_val

    else if message_type == "data"
      if not @justdo_chat.isBotUserId(@performing_user)
        throw @_error "data-message-submission-forbidden", "Only bot user ids are allowed to send data messages."

      # Ensure message_obj.msg_type is allowed type for @performing_user (bot)

      bots_definitions = @justdo_chat.getBotsDefinitions()

      if not (bot_definition = bots_definitions[@performing_user])?
        throw @_error "unknown-bot", "Can't send data message, unknown bot: #{@performing_user}"

      if not (message_type_definition = bot_definition.msgs_types[message_obj.type])?
        throw @_error "unknown-data-message-type", "Unknown data message type: #{message_obj.type} for bot: #{@performing_user}"

      {cleaned_val} =
        JustdoHelpers.simpleSchemaCleanAndValidate(
          message_type_definition.data_schema,
          message_obj,
          {self: @, throw_on_error: true}
        )
      message_obj = cleaned_val

    else
      throw @_error "invalid-message-type", "Unknown message type: #{message_type}"

    channel_doc = @getChannelDocNonReactive()

    # Note, if user is already subscribed, @manageSubscribers() will simply ignore the call.
    # Thanks to the channel doc caching, this won't @_cached_channel_doc result in addition
    # requests to the db.
    @manageSubscribers
      add: [@performing_user]

    # Add message to channel.

    message_date = new Date()

    message_doc = 
      channel_id: channel_doc._id
      channel_type: @channel_type
      author: @performing_user
      createdAt: message_date

    if message_type == "txt"
      message_doc.body = message_obj.body
    else if message_type == "data"
      message_doc.data = message_obj

    # write the message
    @justdo_chat.messages_collection.insert message_doc

    # Update messages_count and last_message_date related fields
    @findAndModifyChannelDoc
      update:
        $max:
          last_message_date: message_date
        $inc:
          messages_count: 1

    channel_doc = @getChannelDocNonReactive()
    # The findAndModifyChannelDoc() we just did, brought us back the most recent version
    # of the channel document, we hope that this will be enough to perform the update to
    # the unread fields of the subscribers, without losing data written to the subscribers
    # array between the point we received the udpated doc to the point we perform the update.
    #
    # Once we migrate to mongo v3.6 , we will be able to do the following with one query,
    # without the mentioned risk of data loss.
    #
    # IMPROVEMENT_PENDING_MONGO_MIGRATION

    new_subscribers_array = channel_doc.subscribers

    # changed tracks whether an update is needed at all, if there are no subscribers other than
    # the @performing_user, or if all the subscribers already have their unread flag turned
    # on - there's nothing to do.
    changed = false
    for subscriber in new_subscribers_array
      if subscriber.user_id != @performing_user and subscriber.unread == false
        changed = true

        subscriber.unread = true
        subscriber.iv_unread = message_date
        subscriber.iv_unread_type = "new-msg"

      if subscriber.user_id == @performing_user and subscriber.unread == true
        changed = true

        subscriber.unread = false
        delete subscriber.iv_unread
        delete subscriber.iv_unread_type

        for unread_notification_type, unread_notification_conf of share.unread_channels_notifications_conf
          delete subscriber[unread_notification_conf.processed_notifications_indicator_field_name]

    if changed
      @findAndModifyChannelDoc
        update:
          $set:
            subscribers: new_subscribers_array

    return

  _getChannelMessagesCursorOptionsSchema: new SimpleSchema
    channel_id: # IMPORTANT! @_getChannelMessagesCursor doesn't do any security check.
      type: String
    fields:
      type: Object
      blackbox: true
    limit:
      type: Number

      defaultValue: 10

      max: 1000
  _getChannelMessagesCursor: (options) ->
    # We use the _ internal prefix, since we don't perform any security checks on whether the
    # performing user has access to the provided channel_id.
    #
    # This method shouldn't be exposed to external apis, and assumes security is handled by callee
    #
    # Note, we allow receiving the channel_id as an option, even though this object is for a specific
    # channel, to avoid the need to fetch the channel doc just to obtain its _id in certain situation
    # where the _id is already known to us, see for example the case of the
    # JustdoChat._getSubscribedChannelsRecentActivityCursor.
    #
    # PROPER SECURITY CONSIDERATIONS MUST BE TAKEN ANY TIME YOU DO THIS!!!

    if not options?
      options = {}

    options_schema = @_getChannelMessagesCursorOptionsSchema._schema
    {cleaned_val} =
      JustdoHelpers.simpleSchemaCleanAndValidate(
        @_getChannelMessagesCursorOptionsSchema,
        options,
        {self: @, throw_on_error: true}
      )
    options = cleaned_val

    #
    # IMPORTANT, if you change the following, don't forget to update the collections-indexes.coffee
    # and to drop obsolete indexes (see MESSAGES_FETCHING_INDEX there)
    #

    channel_messages_cursor_query =
      channel_id: options.channel_id

    channel_messages_cursor_options =
      limit: options.limit
      sort:
        createdAt: -1

    if options.fields?
      channel_messages_cursor_options.fields = options.fields

    return @justdo_chat.messages_collection.find(channel_messages_cursor_query, channel_messages_cursor_options)

  getChannelDocCursor: (options) ->
    # Returns a cursor for the channel.
    #
    # Cursor, of course, might be empty .

    #
    # IMPORTANT, if you change the following, don't forget to update the collections-indexes.coffee
    # and to drop obsolete indexes (see CHANNEL_IDENTIFIER_INDEX there)
    #

    return @justdo_chat.channels_collection.find(@channel_identifier, options)

  _channelMessagesPublicationHandlerOptionsSchema: new SimpleSchema
    limit:
      type: Number

      defaultValue: 10

      max: 1000
    provide_authors_details:
      # If set to true, details about authors of messages in this publication,
      # will be provided by the publication, and will be available under the

      type: Boolean

      defaultValue: false

      optional: true

  channelMessagesPublicationHandler: (publish_this, options) ->
    self = @

    if not options?
      options = {}

    options_schema = @_channelMessagesPublicationHandlerOptionsSchema._schema
    if (pre_validation_limit = options?.limit)?
      if pre_validation_limit > (max_limit = options_schema.limit.max)
        # Just to provide a more friendly error message for that case (v.s the one simple schema will throw)
        throw @_error "invalid-options", "Can't subscribe to more than #{max_limit} channel messages"

    {cleaned_val} =
      JustdoHelpers.simpleSchemaCleanAndValidate(
        @_channelMessagesPublicationHandlerOptionsSchema,
        options,
        {self: @, throw_on_error: true}
      )
    options = cleaned_val

    channel_messages_authors_details_collection_name =
      JustdoChat.jdc_channel_messages_authors_details_collection_name

    authors_details_sent = {} # holds the authors to which we sent details about, details include, first name, last name, user avatar
                              # structure:
                              # {
                              #   user_id: count of messages in the publication that had him as author
                              # }

    message_id_to_author_id = {} # Is used to be able to know which author wrote a message when
                                 # the remove hook of the messages_tracker is called for a message
                                 # (so we can report it isn't necessary any longer).

    reportAuthorDetailsRequired = (message_id, author_id) ->
      if not options.provide_authors_details
        return

      message_id_to_author_id[message_id] = author_id

      if not authors_details_sent[author_id]?
        authors_details_sent[author_id] = 1

        publish_this.added channel_messages_authors_details_collection_name, author_id, APP.accounts.findOnePublicBasicUserInfo(author_id)
      else 
        authors_details_sent[author_id] += 1

      return

    reportAuthorDetailsNotRequired = (message_id) ->
      if not options.provide_authors_details
        return

      author_id = message_id_to_author_id[message_id]
      delete message_id_to_author_id[message_id] # If reportAuthorDetailsNotRequired is called, it implies that the message got removed from the publication, no need to keep a reference

      authors_details_sent[author_id] -= 1 # We assume that if an author is reported to be not required any longer, he was reported before to be required.

      if authors_details_sent[author_id] == 0
        # No one need the details about the previous channel.
        delete authors_details_sent[author_id]

        publish_this.removed channel_messages_authors_details_collection_name, author_id

      return

    #
    # Messages related procedures (called by the channel related procedures)
    #
    messages_tracker = null
    publishMessages = (channel_id) =>
      if messages_tracker?
        publish_this.stop()

        throw self._error "fatal", "We should never get to situation where publishMessages() is called twice"

      # See IMPORTANT few lines above
      messages_cursor = @_getChannelMessagesCursor
        channel_id: channel_id
        limit: options.limit
        fields:
          channel_id: 1
          body: 1
          data: 1
          author: 1
          createdAt: 1

      messages_collection_name =
        JustdoHelpers.getCollectionNameFromCursor(messages_cursor)

      messages_tracker = messages_cursor.observeChanges
        added: (id, data) ->
          publish_this.added messages_collection_name, id, data

          reportAuthorDetailsRequired(id, data.author)

          return

        changed: (id, data) ->
          publish_this.changed messages_collection_name, id, data

          # We don't care of changes to author, we assume such changes won't happen

          return

        removed: (id) ->
          publish_this.removed messages_collection_name, id

          reportAuthorDetailsNotRequired(id)

          return

      return

    #
    # Channel related procedures
    #
    channel_fields_to_fetch = _.extend
      _id: 1

      channel_type: 1
      messages_count: 1
      last_message_date: 1

      "subscribers.user_id": 1
      "subscribers.unread": 1
      "subscribers.last_read": 1

    for type_specific_field in @getChannelTypeIdentifiyingAndAugmentedFields()
      channel_fields_to_fetch[type_specific_field] = 1

    channel_doc_cursor = @getChannelDocCursor({fields: channel_fields_to_fetch})

    channels_collection_name =
      JustdoHelpers.getCollectionNameFromCursor(channel_doc_cursor)

    channel_tracker = channel_doc_cursor.observeChanges
      added: (id, data) ->
        publish_this.added channels_collection_name, id, data

        publishMessages(id)

        return

      changed: (id, data) ->
        publish_this.changed channels_collection_name, id, data

        return

      removed: (id) ->
        publish_this.removed channels_collection_name, id

        # Note, we rely on publish_this.onStop below to stop the messages_tracker
        # and on Meteor ddp implementation to rid all the messages docs, even if
        # they weren't actually removed from the messages collection (this will
        # happen when the channel doc got removed, but not its messages).
        #
        # Note, that stopping a tracker doesn't trigger a call to its removed method
        # with all the docs that it tracked.
        # Hence, if we won't stop the publication altogether, we will have to maintain
        # our own list of messages that been published as a result of the messages_tracker
        # above.
        # The case of removed channel should be extremely rare, so I just decided to stop
        # the publication completely if it happened, and not care about it. (D.C)
        publish_this.stop()

        return

    #
    # onStop setup + ready()
    #
    publish_this.onStop ->
      channel_tracker.stop()

      messages_tracker?.stop()

      return

    publish_this.ready()

    return

  #
  #
  #
  # METHODS/VALS THAT CAN/SHOULD BE IMPLEMENTED/SET BY INHERITORS
  #
  #
  #

  #
  # All the following CAN be set/implimented by the inheriting channels constructors
  #
  _errors_types:
    _.extend {}, JustdoHelpers.common_errors_types,
      "db-error": "Database error"
      "invalid-channel": "Invalid channel" # Note: we throw invalid-channel both when
                                           # @requireValidChannelIdentifier() returns false
                                           # and when @requirePerformingUserPermittedToAccessChannel()
                                           # since we don't want to leak existence information
                                           # to user without access.
      "access-forbidden": "Access forbidden" # Note: the performing user will see this error when he'll
                                             # try to perform actions on this channel with users that
                                             # has no permission to access this channel.
                                             # If the performing user will try to access this channel
                                             # without permission he'll see the "invalid-channel" thrown
                                             # (he won't know whether the channel exist or not).
      "invalid-message-type": "Unknown message type"
      "data-message-submission-forbidden": "Data message submission forbidden"
      "unknown-bot": "Unknown bot"

  #
  # All the following SHOULD be set/implimented by the inheriting channels constructors
  #
  channel_type: "unknown" # dash-separated

  channel_name_dash_separated: "channel-base-server" # for logging purposes

  channel_identifier_schema: new SimpleSchema {}

  isValidChannelIdentifier: ->
    # This method defines whether or not @channel_identifier is valid. It should return true if
    # it is valid, false otherwise.

    # You can assume that the @channel_identifier been cleaned and verified against the
    # provided @channel_identifier_schema .

    # This method is called by @_immediateInit(), in the same js event loop in which we init
    # the object. We throw the "invalid-channel" error if @isValidChannelIdentifier returns false.
    # So all your methods can assume @channel_identifier is valid.

    # Note, we didn't define @isValidChannelIdentifier in a general way, in which the channel
    # identifier is passed as the first argument, since we want implementation of @isValidChannelIdentifier()
    # to be able to assume that it is called for the current channel identifier so it'll be able to perform
    # caching of related documents required from the db that we use to determine whether or not the channel
    # identifier is valid. It is very likely that these related documents will also be used by calls to
    # areUsersPermittedToAccess() and so, by enabling caching, we can request the related docs only once in this stage.
    #
    # See the task channel server constructor as an example.

    return false

  _getUsersAccessPermission: (users_ids) ->
    # This method defines who should have access to this channel.
    #
    # Should return an object of the following structure:
    #
    # {
    #   permitted: [] # The users from users_ids that are allowed to access
    #.  not_permitted: [] # The users in users_ids that aren't allowed to access
    # }
    #
    # YOU MUST (!) return both properties, even if one is empty.
    #
    # This method should be called by the @getUsersAccessPermission() proxy, when call this way, we guarentee
    # that users_ids is a non empty array of strings (and if it's not the case we throw an invalid-argument exception).
    #
    # A user that is regarded as permitted to access should be allowed to perform all actions on the channel and
    # consume all its data, e.g.:
    #
    # * Subscribe to the channel publications.
    # * Subscribe to notifications (either by himself, or by 3rd pary that has access as well).
    # * Send messages to the channel.
    #
    # This method is called by @_immediateInit(), in the same js event loop in which we init the object,
    # *after* we verified the @channel_identifier agains @isValidChannelIdentifier() (exception is thrown if it isn't!)
    #
    # @_immediateInit() will call this function with [@performing_user] as its argument and will throw the
    # "invalid-channel" exception if user is not permitted to access the channel.
    # Note, we throw the "invalid-channel" exception and not the "access-forbidden" exception, to avoid
    # providing data to users that shouldn't be aware of it.
    #
    # You can safely assume @channel_identifier is valid and that, if @isValidChannelIdentifier() performed
    # any caching for related documents, they'll be available by the time @_getUsersAccessPermission()
    # is called.

    return {permitted: [], not_permitted: users_ids.slice()}

  loadChannel: ->
    # This method is called after we verified @channel_identifier and ensured that @performing_user
    # is allowed to access it.
    #
    # This method is called as part of the _immediateInit() call, throwing
    # exceptions here will guarentee no operations will perform on the channel.
    #
    # Since this method is called in the same event loop tick of the object init,
    # you can assign here properties to `this` you want to be available to other
    # methods you define for this channel.

    return

  getChannelAugmentedFields: ->
    # In some cases, like the case of the tasks channel, you might want to keep, for query optimizations, extra
    # non-normal-form fields, like the project_id in the tasks channel document (even though the project_id
    # can be derived from the tasks collection), or other data about the channel in the channel document on
    # the Mongo DB. We call these extra non-identifying fields 'Augmented Fields'.
    #
    # You should define the schema for the Augmented Fields under task-channel-both-register.coffee.
    #
    # Here you can return their value for the current channel, these value will be used when creating the channel
    # document.
    #
    # Important! we don't validate the provided Augmented Fields values against the channel_augmented_fields_simple_schema
    # of the channel conf.
    #
    # The augmented fields of all types are transmitted as part of the jdcSubscribedChannelsRecentActivity
    # publication.

    return {}

  getChannelRecentActivitySupplementaryDocs: ->
    # Should return an array of the following structure:
    #
    # [
    #   ["collection_id", "doc_id", doc]
    #   ["collection_id", "doc_id", doc]
    # ]
    #
    # These docs will be published by the JustdoChat.subscribedChannelsRecentActivityPublicationHandler
    # when this channel is published.
    #
    # The supplementary docs aren't live (non-reactive). They can't be changed once sent.
    # read comment under the jdcSubscribedChannelsRecentActivity publication definition (publications.coffee)
    # for full details.
    #
    # The handler will take care of removing these docs from the publication when the channel shouldn't
    # be part of the publication any longer.

    return []

  getBottomWindowsChannelsSupplementaryDocs: ->
    # Should return an array of the following structure:
    #
    # [
    #   ["collection_id", "doc_id", doc]
    #   ["collection_id", "doc_id", doc]
    # ]
    #
    # These docs will be published by the JustdoChat.bottomWindowsPublicationHandler
    # when this channel is published.
    #
    # The supplementary docs aren't live (non-reactive). They can't be changed once sent.
    # read comment under the jdcBottomWindows publication definition (publications.coffee)
    # for full details.
    #
    # The handler will take care of removing these docs from the publication when the channel shouldn't
    # be part of the publication any longer.

    return []

share.ChannelBaseServer = ChannelBaseServer
