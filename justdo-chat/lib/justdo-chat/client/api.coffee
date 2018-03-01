channel_type_to_channels_constructors = share.channel_type_to_channels_constructors

_.extend JustdoChat.prototype,
  _immediateInit: ->
    @_initRecentActivitySupplementaryPseudoCollections()

    @_subscribed_channels_recent_activity_subscription_dep = new Tracker.Dependency()
    @_initial_subscribed_channels_recent_activity_subscription_ready = new ReactiveVar false

    @_setupChannelsRecentActivitySubscriptionsDestroyer()

    return

  _initRecentActivitySupplementaryPseudoCollections: ->
    @recent_activity_supplementary_pseudo_collections = {}

    for channel_type, channel_type_conf of share.channel_types_conf
      if (sup_pseudo_cols = channel_type_conf.recent_activity_supplementary_pseudo_collections)?
        for col_id, col_name of sup_pseudo_cols
          @recent_activity_supplementary_pseudo_collections[col_id] = new Mongo.Collection(col_name)

    return

  _setupHtmlTitlePrefixController: ->
    count_observer_autorun = Tracker.autorun ->
      count = APP.collections.JDChatInfo.findOne("subscribed_unread_channels_count")?.count or 0

      if count > 0
        APP.page_title_manager.setPrefix("(#{count})")
      else
        APP.page_title_manager.setPrefix("")

      return

    @onDestroy ->
      count_observer_autorun.stop()

    return

  _deferredInit: ->
    if @destroyed
      return

    return

  generateClientChannelObject: (channel_type, channel_conf, other_options) ->
    @requireAllowedChannelType(channel_type)
    check channel_conf, Object

    # See both/static-channel-registrar.coffee
    channel_constructor_name = channel_type_to_channels_constructors[channel_type].client

    conf = _.extend {
      justdo_chat: @
      channel_conf: channel_conf
    }, other_options

    return new share[channel_constructor_name](conf)


  _subscribed_channels_recent_activity_subscription: null
  _active_channels_recent_activity_subscription_options: null
  subscribeChannelsRecentActivityPublication: (options, callbacks) ->
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
    # 1. We maintain a single subscription at any given time.
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
          @logger.debug("Stop channels recent activity subscription that became ready after JustdoChat object destroyed")

          subscription.stop()

          return

        # If a channel subscription already exists stop it now, after the new subscription is ready
        # see comment for the method above for reason.
        if @_subscribed_channels_recent_activity_subscription?
          @logger.debug("Channel subscription replaced")

          @_subscribed_channels_recent_activity_subscription.stop()
        else
          @_initial_subscribed_channels_recent_activity_subscription_ready.set true


        @_subscribed_channels_recent_activity_subscription = subscription
        @_subscribed_channels_recent_activity_subscription_dep.changed()
        @_active_channels_recent_activity_subscription_options = options

        original_callbacks?.onReady?()

        return

      onStop: (err) =>
        original_callbacks?.onStop?(err)

        return

    subscription =
      @subscribeSubscribedChannelsRecentActivity options, callbacks

    return

  stopChannelsRecentActivityPublication: ->
    @_subscribed_channels_recent_activity_subscription?.stop()

    @_subscribed_channels_recent_activity_subscription = null
    @_subscribed_channels_recent_activity_subscription_dep.changed()

    return

  _setupChannelsRecentActivitySubscriptionsDestroyer: ->
    # Called from @_immediateInit()
    @onDestroy =>
      @logger.debug("Channel messages subscription stopped")

      @stopChannelsRecentActivityPublication()

      return

    return

  getSubscribedChannelsRecentActivityCount: ->
    return APP.collections.JDChatInfo.findOne("subscribed_channels_recent_activity_count")?.count

  getSubscribedChannelsRecentActivityState: ->
    # 4 potential returned values
    #
    # "no-sub": No subscription created yet
    # "initial-not-ready": The initial (first, pre infinite scroll) subscription created by requestChannelMessages isn't ready yet
    # "more": some messages haven't been returned by the subscription
    # "all": all the messages belonging to this channel been loaded by the subscription.

    @_subscribed_channels_recent_activity_subscription_dep.depend()
    if not @_subscribed_channels_recent_activity_subscription?
      return "no-sub"

    if @_initial_subscribed_channels_recent_activity_subscription_ready.get() == false
      return "initial-not-ready"

    if not (subscription_limit = @_active_channels_recent_activity_subscription_options?.limit)?
      # We shouldn't get here...
      throw @_error "fatal", "Can't find active subscription limit"

    available_recent_activity_messages_count = @getSubscribedChannelsRecentActivityCount()
    if available_recent_activity_messages_count > subscription_limit
      return "more"
    else
      return "all"

  # XXX there's a generalization opportunity here, we are doing something very similar in the
  # channel's object, see: requestChannelMessages() under channel-base-client.coffee
  _waiting_for_previous_request_subscribed_channels_recent_activity_to_complete: false
  requestSubscribedChannelsRecentActivity: (options) ->
    # If no subscribed channels recent activity existing yet, will subscribe with limit set
    # to initial_messages_to_request, otherwise, if there are more messages that we haven't
    # fetched yet with the messages subscription, requests additional_messages_to_request .

    options = _.extend {}, {
      initial_messages_to_request: 10
      additional_messages_to_request: 30
      onReady: null
    }, options

    if @_waiting_for_previous_request_subscribed_channels_recent_activity_to_complete
      @logger.debug "Waiting for previous @requestSubscribedChannelsRecentActivity() to complete"

      return

    subscribed_channels_activity_state = Tracker.nonreactive =>
      return @getSubscribedChannelsRecentActivityState()

    performSubscription = (subscription_options) =>
      @_waiting_for_previous_request_subscribed_channels_recent_activity_to_complete = true

      @subscribeChannelsRecentActivityPublication subscription_options,
        onReady: =>
          @_waiting_for_previous_request_subscribed_channels_recent_activity_to_complete = false

          JustdoHelpers.callCb options.onReady

          return

      return

    if subscribed_channels_activity_state == "no-sub"
      @logger.debug "Initial channel messages subscription"

      performSubscription({limit: options.initial_messages_to_request})

      return
    else if subscribed_channels_activity_state == "initial-not-ready"
      @logger.debug "Channel subscription not ready"

      return
    else if subscribed_channels_activity_state == "more"
      @logger.debug "Channel load more messsages"

      new_limit =
        @_active_channels_recent_activity_subscription_options.limit + options.additional_messages_to_request

      # Use same options as previous call, change only the limit
      options = _.extend {}, options, {limit: new_limit}

      performSubscription({limit: options.limit})

      return
    else
      @logger.debug "All messages subscribed"

      return

    return

  destroy: ->
    if @destroyed
      @logger.debug "Destroyed already"

      return

    _.each @_on_destroy_procedures, (proc) -> proc()

    @destroyed = true

    @logger.debug "Destroyed"

    return