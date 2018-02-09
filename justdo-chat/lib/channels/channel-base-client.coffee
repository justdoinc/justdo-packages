ChannelBaseClient = (options) ->
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

  # React to invalidations
  if Tracker.currentComputation?
    Tracker.onInvalidate =>
      @logger.debug "Enclosing computation invalidated, destroying"
      @destroy() # defined in client/api.coffee

  # on the client, call @_immediateInit() in an isolated
  # computation to avoid our init procedures from affecting
  # the encapsulating computation (if any)
  Tracker.nonreactive =>
    @_immediateInit()

  Meteor.defer =>
    @_deferredInit()

  @logger.debug "Init done"

  return @

Util.inherits ChannelBaseClient, EventEmitter

_.extend ChannelBaseClient.prototype,
  #
  # The following SHOULDN'T change by the inheriting channels constructors
  #
  _error: JustdoHelpers.constructor_error

  default_options: {}

  options_schema:
    both:
      custom_channels_collection:
        # In some situations, we want to use custom collection as the channels collection.
        # An example for that can be the case of the recent activity dropdown, where we get
        # from the publication information about involved channels into pseudo collection
        # to avoid polluting the real collection.

        # If the custom_channels_collection is provided we'll use it instead of
        # @justdo_chat.channels_collection
        type: "skip-type-check"
        optional: true
        bind_to_instance: false

      custom_messages_collection:
        # Read custom_channels_collection to get idea about the motivation.

        # If the custom_channels_collection is provided we'll use it instead of
        # @justdo_chat.messages_collection

        type: "skip-type-check"
        optional: true
        bind_to_instance: false

      justdo_chat:
        type: "skip-type-check"
        optional: false
        bind_to_instance: true

      channel_conf:
        type: Object
        optional: false
        blackbox: true
        bind_to_instance: true

  _immediateInit: ->
    @_verifyChannelConfObjectAgainstSchema()

    # Inits related to the messages subscriptions (note, we don't subscribe automatically)
    @_setupChannelMessagesSubscriptionsDestroyer()

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

  _getChannelsCollection: ->
    if (custom_collection = @options.custom_channels_collection)?
      return custom_collection

    return @justdo_chat.channels_collection

  _getMessagesCollection: ->
    if (custom_collection = @options.custom_messages_collection)?
      return custom_collection

    return @justdo_chat.messages_collection

  _verifyChannelConfObjectAgainstSchema: ->
    {cleaned_val} =
      JustdoHelpers.simpleSchemaCleanAndValidate(
        @channel_conf_schema,
        @channel_conf,
        {self: @, throw_on_error: true}
      )
    @channel_conf = cleaned_val

    return

  sendMessage: (body, cb) ->
    @justdo_chat.sendMessage @channel_type, @getChannelIdentifier(), {body: body}, =>
      @emit "message-sent"

      JustdoHelpers.callCb cb

    return

  toggleChannelUnreadState: (cb) ->
    if not (subscriber_doc = @getChannelSubscriberDoc(Meteor.userId()))?
      # We shouldn't get here
      console.warn "Channel is not ready yet"

      return

    current_state = subscriber_doc.unread

    new_state = not current_state

    @setChannelUnreadState(new_state)

    return

  setChannelUnreadState: (new_state, cb) ->
    if not (subscriber_doc = @getChannelSubscriberDoc(Meteor.userId()))?
      # We shouldn't get here
      console.warn "Channel is not ready yet"

      return

    current_state = subscriber_doc.unread

    if new_state == current_state
      # Nothing to do

      return

    @justdo_chat.setChannelUnreadState @channel_type, @getChannelIdentifier(), new_state, =>
      JustdoHelpers.callCb cb

    return

  manageSubscribers: (update, cb) ->
    @justdo_chat.manageSubscribers @channel_type, @getChannelIdentifier(), update, =>
      JustdoHelpers.callCb cb

      return

    return

  _channel_messages_subscription: null
  _active_channel_messages_subscription_options: null
  subscribeChannelMessagesPublication: (options, callbacks) ->
    # Args:
    #
    # options: Supported options:
    #
    # {
    #   limit: how many tasks we should fetch - the max supported limit can be found on channels/channel-base-server.coffee see @_getChannelMessagesCursorOptionsSchema()
    # }
    # 
    # Return the returned value returned by the generated Meteor.subscribe()
    #
    # callbacks is of the same structure/behavior of Meteor.subscribe(... , callbacks) .
    # A bit non-trivial callbacks, so check docs.meteor.com for full details.
    #
    # Implementation notes:
    #
    # 1. We maintain a single subscription per channel.
    #
    # If the user changes the options, we subscribe to the channel messages subscription with the
    # new requested options, wait for the docs to ready ddp message, and only then unsubscribe existing
    # subscription (if any). That will prevent ddp from sending docs we already got (thanks to ddp
    # mergebox feature.)

    options = _.extend {limit: 10}, options

    # Normalize callbacks (there are two ways they can be Meteor.subscribe callbacks can be provided, check docs)
    if _.isFunction callbacks
      callbacks = {onReady: callbacks}

    subscription = null
    original_callbacks = callbacks
    callbacks =
      onReady: =>
        if @destroyed
          @logger.debug("Stop channel subscription that became ready after channel object destroyed")

          subscription.stop()

          return

        # If a channel subscription already exists stop it now, after the new subscription is ready
        # see comment for the method above for reason.
        if @_channel_messages_subscription?
          @logger.debug("Channel subscription replaced")

          @_channel_messages_subscription.stop()

        @_channel_messages_subscription = subscription
        @_active_channel_messages_subscription_options = options

        original_callbacks?.onReady?()

        return

      onStop: (err) =>
        original_callbacks?.onStop?(err)

        return

    subscription =
      @justdo_chat.subscribeChannelMessages @channel_type, @getChannelIdentifier(), options, callbacks

    return

  _setupChannelMessagesSubscriptionsDestroyer: ->
    # Called from @_immediateInit()
    @onDestroy =>
      @logger.debug("Channel messages subscription stopped")

      @_channel_messages_subscription?.stop()
      @_active_subscription_limit_option = null

      return

    return

  getMessagesSubscriptionChannelDoc: ->
    return @_getChannelsCollection().findOne(@getChannelIdentifier())

  isChannelExistAndReady: ->
    return @getMessagesSubscriptionChannelDoc()?

  getMessagesSubscriptionChannelDocId: ->
    return @getMessagesSubscriptionChannelDoc()?._id

  getMessagesSubscriptionCursorInNaturalOrder: ->
    # Returns null if we can't come up with the channel_id == things aren't ready
    # Will return the cursor otherwise.
    if not (channel_id = @getMessagesSubscriptionChannelDocId())?
      return null

    return @_getMessagesCollection().find({channel_id: channel_id}, {sort: {createdAt: 1}})

  isMessagesSubscriptionHasDocs: ->
    # Returns null if we can't come up with the channel_id == things aren't ready
    # Will return the cursor otherwise.
    if not (channel_id = @getMessagesSubscriptionChannelDocId())?
      return false

    return @_getMessagesCollection().findOne({channel_id: channel_id})?

  getChannelMessagesSubscriptionState: ->
    # 4 potential returned values
    #
    # "no-sub": No subscription created yet
    # "no-channel-doc": Subscription not ready yet/channel doc hasn't been created yet
    # "more": some messages haven't been returned by the subscription
    # "all": all the messages belonging to this channel been loaded by the subscription.

    if not @_channel_messages_subscription?
      return "no-sub"

    if not (channel_doc = @getMessagesSubscriptionChannelDoc())?
      return "no-channel-doc"

    if not (subscription_limit = @_active_channel_messages_subscription_options?.limit)?
      # We shouldn't get here...
      throw @_error "fatal", "Can't find active subscription limit"

    if channel_doc.messages_count > subscription_limit
      return "more"
    else
      return "all"

  _waiting_for_previous_request_channel_messages_to_complete: false
  requestChannelMessages: (options) ->
    # If no channel messages subscription existing yet, will subscribe with limit set
    # to initial_messages_to_request, otherwise, if there are more messages that we haven't
    # fetched yet with the messages subscription, requests additional_messages_to_request .

    options = _.extend {}, {
      initial_messages_to_request: 10
      additional_messages_to_request: 30
      onReady: null
    }, options

    if @_waiting_for_previous_request_channel_messages_to_complete
      @logger.debug "Waiting for previous @requestChannelMessages() to complete"

      return

    channel_messages_subscription_state = @getChannelMessagesSubscriptionState()

    performSubscription = (subscription_options) =>
      @_waiting_for_previous_request_channel_messages_to_complete = true

      @subscribeChannelMessagesPublication subscription_options,
        onReady: =>
          @_waiting_for_previous_request_channel_messages_to_complete = false

          JustdoHelpers.callCb options.onReady

          return

      return

    if channel_messages_subscription_state == "no-sub"
      @logger.debug "Initial channel messages subscription"

      performSubscription({limit: options.initial_messages_to_request})

      return
    else if channel_messages_subscription_state == "no-channel-doc"
      @logger.debug "Channel empty/not ready"

      return
    else if channel_messages_subscription_state == "more"
      @logger.debug "Channel load more messsages"

      new_limit =
        @_active_channel_messages_subscription_options.limit + options.additional_messages_to_request

      # Use same options as previous call, change only the limit
      options = _.extend {}, options, {limit: new_limit}

      performSubscription(options)

      return
    else
      @logger.debug "All messages subscribed"

      return

    return

  getChannelSubscriberDoc: (user_id) ->
    # Returns the document from the subscribers array of the channel belonging
    # to user_id, undefined otherwise.
    #
    # Returns undefined also when the channel isn't ready/doesn't exist

    if not (channel_doc = @getMessagesSubscriptionChannelDoc())?
      return undefined

    if user_id == Meteor.userId() and (unread = channel_doc.unread)?
      # Special case, if we got the unread property, the subscription that populated
      # the collection is the recent activity publication: see subscribedChannelsRecentActivityPublicationHandler()
      # all the channels returned by this publication are subscribed by the logged-in
      # member, and the unread state is indicates whether the current user has unread messages
      # we can construct from it *fake* subscriber doc.
      return {user_id: user_id, unread: unread}
    

    return _.find channel_doc.subscribers, (subscriber) -> subscriber.user_id == user_id

  isUserSubscribedToChannel: (user_id) ->
    # Returns false if user_id isn't subscribed, or channel isn't ready/doesn't exist
    # true if subscribed

    if not (subscriber_doc = @getChannelSubscriberDoc(user_id))?
      return false

    return true

  toggleUserSubscriptionToChannel: (user_id) ->
    if not @isChannelExistAndReady()
      @logger.warn "Channel not ready yet to toggle user subscription"

      return

    if @isUserSubscribedToChannel(user_id)
      @manageSubscribers({remove: [user_id]})
    else
      @manageSubscribers({add: [user_id]})

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
    _.extend {}, JustdoHelpers.common_errors_types, {}

  channel_conf_schema: new SimpleSchema {}

  loadChannel: ->
    # This method is where you should:
    #
    # * Make sure channel_conf is valid
    #
    # This method is called as part of the _immediateInit() call, throwing
    # exceptions here will guarentee no operations will perform on this channel.
    #
    # Since this method is called in the same event loop tick of the object init,
    # you can assign here properties to `this` you want to be available to other
    # methods you define for this channel.
    #
    # You can assume that the @channel_conf been cleaned and verified against the
    # provided @channel_conf_schema .

    return

  #
  # All the following SHOULD be set/implimented by the inheriting channels constructors
  #
  channel_type: "unknown" # dash-separated

  channel_name_dash_separated: "channel-base-client" # for logging purposes

  getChannelIdentifier: ->
    # Should return the *minimal* object with which a find() query on the channels schema can identify
    # the current channel.
    #
    # In some cases, like the case of the tasks channel, you might keep for query optimizations extra
    # non-normal-form fields, like the project_id in the tasks channel document (even though the project_id
    # can be derived from the tasks collection).
    #
    # Even if you store such data, use here the minimal find object with which the channel can be
    # identified (in the tasks channel case, that is the task_id alone).
    #
    # Read more about how to set non-identifying channel fields, which we call 'Augmented Fields', under:
    # @getChannelAugmentedFields() , channel-base-server.coffee .
    #
    # On the server, the channel identifier object will be provided to the backend channel type constructor
    # as part of its options argument.
    #
    # The channel identifiers fields of all types are transmitted as part of the jdcSubscribedChannelsRecentActivity
    # publication

    return {}

share.ChannelBaseClient = ChannelBaseClient
