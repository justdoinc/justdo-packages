ChannelBaseServer = (options) ->
  # derived from skeleton-version: v0.0.11-onepage_skeleton

  EventEmitter.call this

  @destroyed = false

  @logger = Logger.get(@channel_name_dash_separated)
  @JA = JustdoAnalytics.setupConstructorJA(@, @channel_name_dash_separated)

  @logger.debug "Init begin"

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

  @logger.debug "Init done"

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

    console.log "TODO Ensure index for @getChannelDoc() findAndModify"

    result = @justdo_chat.channels_collection.findAndModify
      query: @channel_identifier,
      update: update
      upsert: upsert
      new: true # return the doc after the modification

    if result.ok != 1
      throw @_error "db-error", "Unknown database error when trying to create channel"

    @_cached_channel_doc = result.value

    return result.value

  getChannelDoc: (allow_cache=true) ->
    # Retrieves the channel doc for the identifier. Creates one if one doesn't exists.

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
    # We assume @getChannelAugmentedFields() complies with the channel conf channel_augemented_fields_simple_schema
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
    # Both add, and remove array are filtered through the @removeNonPermittedUsers()
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

    # Get rid of non permitted users ids
    update.add = @removeNonPermittedUsers(update.add)
    update.remove = @removeNonPermittedUsers(update.remove)

    channel_doc = @getChannelDoc()

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
      unread = false
      if user_id != @performing_user and channel_doc.messages_count != 0
        # We turn the unread flag on, only for users that aren't the performing user
        # (which necessarily see this channel), and if there are messages at all
        unread = true

      add_query_items.push {user_id: user_id, unread: unread}

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

  _sendMessageMessageObjectSchema: new SimpleSchema
    body:
      # Note, simple schema takes care of .trim() the value for us

      type: String

      min: JustdoChat.schemas.MessagesSchema._schema.body.min
      max: JustdoChat.schemas.MessagesSchema._schema.body.max
  sendMessage: (message_obj) ->
    messages_schema = @justdo_chat.getMessagesSchema()
    if message_obj?.body?.length > (max_task_length = messages_schema.body.max)
      # Just to provide a more friendly error message for that case (v.s the one simple schema will throw)
      throw @_error "invalid-message", "Message can't be longer than #{max_task_length} charecters"

    {cleaned_val} =
      JustdoHelpers.simpleSchemaCleanAndValidate(
        @_sendMessageMessageObjectSchema,
        message_obj,
        {self: @, throw_on_error: true}
      )
    message_obj = cleaned_val

    channel_doc = @getChannelDoc()

    # Note, if user is already subscribed, @manageSubscribers() will simply ignore the call.
    # Thanks to the channel doc caching, this won't @_cached_channel_doc result in addition
    # requests to the db.
    @manageSubscribers
      add: [@performing_user]

    # Add message to channel.

    message_date = new Date()

    # write the message
    @justdo_chat.messages_collection.insert
      channel_id: channel_doc._id
      channel_type: @channel_type
      body: message_obj.body
      author: @performing_user
      createdAt: message_date

    # Update messages_count and last_message_date related fields
    @findAndModifyChannelDoc
      update:
        $max:
          last_message_date: message_date
        $inc:
          messages_count: 1

    channel_doc = @getChannelDoc()
    # The findAndModifyChannelDoc() we just did, brought us back the most recent version
    # of the channel document, we hope that this will be enough to perform the update to
    # the unread fields of the subscribers, without losing data written to the subscribers
    # array between the point we received the udpated doc to the point we perform the update.
    #
    # Once we migrate to mongo v3.6 , we will be able to do the following with one query,
    # without the mentioned risk of data loss.

    new_subscribers_array = channel_doc.subscribers

    # changed tracks whether an update is needed at all, if there are no subscribers other than
    # the @performing_user, or if all the subscribers already have their unread flag turned
    # on - there's nothing to do.
    changed = false
    for subscriber in new_subscribers_array
      if subscriber.user_id != @performing_user and subscriber.unread == false
        changed = true

        subscriber.unread = true

    if changed
      @findAndModifyChannelDoc
        update:
          $set:
            subscribers: new_subscribers_array

    return

  _getChannelMessagesCursorOptionsSchema: new SimpleSchema
    limit:
      # Note, simple schema takes care of .trim() the value for us

      type: Number

      defaultValue: 10

      max: 1000
  getChannelMessagesCursor: (options) ->
    if not options?
      options = {}

    options_schema = @_getChannelMessagesCursorOptionsSchema._schema
    if (pre_validation_limit = options?.limit)?
      if pre_validation_limit > (max_limit = options_schema.limit.max)
        # Just to provide a more friendly error message for that case (v.s the one simple schema will throw)
        throw @_error "invalid-options", "Can't subscribe to more than #{max_limit} channel messages"

    {cleaned_val} =
      JustdoHelpers.simpleSchemaCleanAndValidate(
        @_getChannelMessagesCursorOptionsSchema,
        options,
        {self: @, throw_on_error: true}
      )
    options = cleaned_val

    channel_doc = @getChannelDoc()

    console.log "TODO: ensure index!"

    query = {channel_id: channel_doc._id}

    query_options = 
      sort:
        createdAt: -1
      fields:
        channel_id: 1
        body: 1
        author: 1
        createdAt: 1
      limit: options.limit

    return @justdo_chat.messages_collection.find(query, query_options)

  getChannelDocCursor: ->
    return @justdo_chat.channels_collection.find(@channel_identifier)

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
    # Important! we don't validate the provided Augmented Fields values against the channel_augemented_fields_simple_schema
    # of the channel conf.

    return {}

share.ChannelBaseServer = ChannelBaseServer
