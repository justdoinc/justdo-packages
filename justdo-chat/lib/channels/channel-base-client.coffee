TEMPORARY_MESSAGES = {}
# Temporary messages are messages the user started typing but didn't save yet,
# we provide a layer to store and get such temp messages for channels to prevent
# data loss when the user temporarily hide/remove dom elements that holds chat
# inputs.

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
    @_modes = []
    @_modes_dep = new Tracker.Dependency()

    @_initial_subscription_ready = new ReactiveVar false
    @_channel_messages_subscription_dep = new Tracker.Dependency()

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

  _getChannelSerializedIdentifier: ->
    return @channel_type + "::" + _.map(@getChannelIdentifier(), (val ,key) => key + ":" + val).sort().join("|")

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
    if @isProposedSubscribersEmulationMode()
      @manageSubscribers {add: @proposedSubscribersForNewChannel()}

      # Note, proposed-subscribers-emulation has no effect on existing channels, we aren't
      # worry about turning it off.

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
      # User isn't subscribed to this channel, can't set state.

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

  makeWindowVisible: (cb) ->
    # A proxy to ease calling to the method under the bottom windows manager with the same name
    #
    # cb is called when the operation is completed.

    return @justdo_chat._justdo_chat_bottom_windows_manager.makeWindowVisible @channel_type, @getChannelIdentifier(), {onComplete: cb}

  removeWindow: ->
    # A proxy to ease calling to the method under the bottom windows manager with the same name

    return @justdo_chat._justdo_chat_bottom_windows_manager.removeWindow(@channel_type, @getChannelIdentifier())

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
        else
          @_initial_subscription_ready.set true


        @_channel_messages_subscription = subscription
        @_channel_messages_subscription_dep.changed()
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

      return

    return

  getMessagesSubscriptionChannelDoc: ->
    return @_getChannelsCollection().findOne(@getChannelIdentifier())

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
    # 5 potential returned values
    #
    # "no-sub": No subscription created yet
    # "initial-not-ready": The initial (first, pre infinite scroll) subscription created by requestChannelMessages isn't ready yet
    # "no-channel-doc": Channel doc hasn't been created yet
    # "more": some messages haven't been returned by the subscription
    # "all": all the messages belonging to this channel been loaded by the subscription.

    @_channel_messages_subscription_dep.depend()
    if not @_channel_messages_subscription?
      return "no-sub"

    if @_initial_subscription_ready.get() == false
      return "initial-not-ready"

    if not (channel_doc = @getMessagesSubscriptionChannelDoc())?
      return "no-channel-doc"

    if not (subscription_limit = @_active_channel_messages_subscription_options?.limit)?
      # We shouldn't get here...
      throw @_error "fatal", "Can't find active subscription limit"

    if channel_doc.messages_count > subscription_limit
      return "more"
    else
      return "all"

  # XXX there's a generalization opportunity here, we are doing something very similar in the
  # JustdoChat object, see: requestSubscribedChannelsRecentActivity() there
  _waiting_for_previous_request_channel_messages_to_complete: false
  requestChannelMessages: (options) ->
    # If no channel messages subscription existing yet, will subscribe with limit set
    # to initial_messages_to_request, otherwise, if there are more messages that we haven't
    # fetched yet with the messages subscription, requests additional_messages_to_request .

    options = _.extend {}, {
      initial_messages_to_request: 10
      additional_messages_to_request: 30
      request_authors_details: false
      onReady: null
    }, options

    if @_waiting_for_previous_request_channel_messages_to_complete
      @logger.debug "Waiting for previous @requestChannelMessages() to complete"

      return

    channel_messages_subscription_state = Tracker.nonreactive =>
      return @getChannelMessagesSubscriptionState()

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

      performSubscription({limit: options.initial_messages_to_request, provide_authors_details: options.request_authors_details})

      return
    else if channel_messages_subscription_state == "initial-not-ready"
      @logger.debug "Channel subscription not ready"

      return
    else if channel_messages_subscription_state == "no-channel-doc"
      @logger.debug "No channel doc"

      return
    else if channel_messages_subscription_state == "more"
      @logger.debug "Channel load more messsages"

      new_limit =
        @_active_channel_messages_subscription_options.limit + options.additional_messages_to_request

      # Use same options as previous call, change only the limit
      options = _.extend {}, options, {limit: new_limit}

      performSubscription({limit: options.limit, provide_authors_details: options.request_authors_details})

      return
    else
      @logger.debug "All messages subscribed"

      return

    return

  getSubscribersArray: ->
    # Returns the channel subscribers array, taking into account the 
    # proposed-subscribers-emulation mode, if we can't come up with one
    # return undefined.

    if (channel_doc = @getMessagesSubscriptionChannelDoc())?
      return channel_doc.subscribers

    # ONLY IF THE CHANNEL DOC DOESN'T EXIST, AND UNDER proposed-subscribers-emulation mode:
    # Returns an array of subscribers, with similar structure to the one under:
    # the channel_doc.subscribers
    # Otherwise, returns undefined

    if not @isProposedSubscribersEmulationMode()
      return undefined

    channel_messages_subscription_state = @getChannelMessagesSubscriptionState()

    if channel_messages_subscription_state != "no-channel-doc"
      return undefined

    # We are under a non-initialized channel, under the proposed-subscribers-emulation
    # mode, generate emulated subscribers_array based on proposedSubscribersForNewChannel.

    pseudo_subscribers_ids = @proposedSubscribersForNewChannel()

    subscribers_array = []

    for subscriber_id in pseudo_subscribers_ids
      subscribers_array.push {user_id: subscriber_id, unread: false}

    return subscribers_array

  getChannelSubscriberDoc: (user_id) ->
    # Returns the document from the subscribers array of the channel belonging
    # to user_id, undefined otherwise.
    #
    # Returns undefined also when the channel isn't ready/doesn't exist

    if (channel_doc = @getMessagesSubscriptionChannelDoc())?
      if user_id == Meteor.userId() and (unread = channel_doc.unread)?
        # Special case, if we got the unread property, the subscription that populated
        # the collection is the recent activity publication: see subscribedChannelsRecentActivityPublicationHandler()
        # all the channels returned by this publication are subscribed by the logged-in
        # member, and the unread state is indicates whether the current user has unread messages
        # we can construct from it *fake* subscriber doc.
        return {user_id: user_id, unread: unread}

    if not (subscribers_array = @getSubscribersArray())?
      return undefined

    return _.find subscribers_array, (subscriber) -> subscriber.user_id == user_id

  isUserSubscribedToChannel: (user_id) ->
    # Returns false if user_id isn't subscribed, or channel isn't ready/doesn't exist
    # true if subscribed

    if not (subscriber_doc = @getChannelSubscriberDoc(user_id))?
      return false

    return true

  toggleUserSubscriptionToChannel: (user_id) ->
    # This method needs the channel to be initialized to toggle the user state (it can be refactored to lift this restriction).

    channel_messages_subscription_state = Tracker.nonreactive =>
      return @getChannelMessagesSubscriptionState()

    if channel_messages_subscription_state in ["no-sub", "initial-not-ready", "no-channel-doc"]
      @logger.warn "Channel not ready yet, or not initialized, to toggle user subscription"

      return

    if @isUserSubscribedToChannel(user_id)
      @manageSubscribers({remove: [user_id]})
    else
      @manageSubscribers({add: [user_id]})

    return

  _getModes: ->
    @_modes_dep.depend()

    return @_modes

  _addModes: (modes_ids_array) ->
    @_modes = _.union(@_modes, modes_ids_array)

    @_modes_dep.changed()

    return

  _removeModes: (modes_ids_array) ->
    @_modes = _.difference(@_modes, modes_ids_array)

    @_modes_dep.changed()

    return

  setProposedSubscribersEmulationMode: ->
    # setProposedSubscribersEmulationMode has effect only for non-initialized channels
    # (channels without channel doc), it has **completely no effect** when called for initialized
    # channels.
    #
    # When called for initialized channels, the channel object will enter 'proposed-subscribers-emulation' mode
    # see @operation_modes
    #
    # This will affect all the methods involving pulling info about subscribers, all of them will
    # behave as if the list of users ids returned by @proposedSubscribersForNewChannel() are subscribed
    # to the channel.

    @_addModes(["proposed-subscribers-emulation"])

    return

  stopProposedSubscribersEmulationMode: ->
    @_removeModes(["proposed-subscribers-emulation"])

    return

  isProposedSubscribersEmulationMode: ->
    return @getChannelMessagesSubscriptionState() == "no-channel-doc" and "proposed-subscribers-emulation" in @_getModes()

  saveTempMessage: (message) -> TEMPORARY_MESSAGES[@_getChannelSerializedIdentifier()] = message

  getTempMessage: -> TEMPORARY_MESSAGES[@_getChannelSerializedIdentifier()]

  clearTempMessage: -> delete TEMPORARY_MESSAGES[@_getChannelSerializedIdentifier()]

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

  proposedSubscribersForNewChannel: ->
    # proposedSubscribersForNewChannel lets you to set users ids of members that
    # will be proposed to user for channel before they are created.

    # Is used when under the 'proposed-subscribers-emulation' mode, check comment
    # under: @setProposedSubscribersEmulationMode() and see it being taken into
    # account under: @getSubscribersArray(), @sendMessage().

    # Return empty array if no subscribers to propose.

    return []

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
