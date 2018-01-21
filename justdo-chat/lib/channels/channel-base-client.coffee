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
    @justdo_chat.sendMessage @channel_type, @getChannelIdentifier(), {body: body}, cb

    return

  _channel_messages_subscription: null
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

    # Defaults are set by the server, don't set them here.
    if not options? or not _.isObject(options)
      options = {}

    if not options.limit?
      options.limit = 100 # XXX Until we have the load more button set higher limit

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

  getSubscriptionMessagesCursorInNaturalOrder: ->
    # Returns null if we can't come up with the channel_id == things aren't ready
    # Will return the cursor otherwise.
    if not (channel_doc = @justdo_chat.channels_collection.findOne(@getChannelIdentifier()))?
      return null

    return @justdo_chat.messages_collection.find({channel_id: channel_doc._id}, {sort: {createdAt: 1}})

  isSubscriptionMessagesHasDocs: ->
    # Returns null if we can't come up with the channel_id == things aren't ready
    # Will return the cursor otherwise.
    if not (channel_doc = @justdo_chat.channels_collection.findOne(@getChannelIdentifier()))?
      return false

    return @justdo_chat.messages_collection.findOne({channel_id: channel_doc._id})?

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

    return {}

share.ChannelBaseClient = ChannelBaseClient
