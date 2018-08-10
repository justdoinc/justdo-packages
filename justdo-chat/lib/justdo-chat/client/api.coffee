channel_type_to_channels_constructors = share.channel_type_to_channels_constructors
JustdoChatBottomWindowsManager = share.JustdoChatBottomWindowsManager

_.extend JustdoChat.prototype,
  _immediateInit: ->
    @_initRecentActivitySupplementaryPseudoCollections()

    @_initBottomWindowsSupplementaryPseudoCollections()

    @_subscribed_channels_recent_activity_subscription_dep = new Tracker.Dependency()
    @_initial_subscribed_channels_recent_activity_subscription_ready = new ReactiveVar false

    @_resources_requiring_subscribed_unread_channels_count_subscription_count = 0

    @_subscribed_unread_channels_count_subscription = null

    @_setupChannelsRecentActivitySubscriptionsDestroyer()

    @_setupBotsInfoSubscription()

    return

  _deferredInit: ->
    if @destroyed
      return

    return

  _setupBotsInfoSubscription: ->
    @_jdc_bots_info_subscription = @jdcBotsInfo()

    @onDestroy =>
      @_jdc_bots_info_subscription.stop()

    return

  _initRecentActivitySupplementaryPseudoCollections: ->
    @recent_activity_supplementary_pseudo_collections = {}

    for channel_type, channel_type_conf of share.channel_types_conf
      if (sup_pseudo_cols = channel_type_conf.recent_activity_supplementary_pseudo_collections)?
        for col_id, col_name of sup_pseudo_cols
          @recent_activity_supplementary_pseudo_collections[col_id] = new Mongo.Collection(col_name)

    return

  _initBottomWindowsSupplementaryPseudoCollections: ->
    @bottom_windows_supplementary_pseudo_collections = {}

    for channel_type, channel_type_conf of share.channel_types_conf
      if (sup_pseudo_cols = channel_type_conf.bottom_windows_supplementary_pseudo_collections)?
        for col_id, col_name of sup_pseudo_cols
          @bottom_windows_supplementary_pseudo_collections[col_id] = new Mongo.Collection(col_name)

    return

  _setupHtmlTitlePrefixController: ->
    @requireSubscribedUnreadChannelsCountSubscription()

    count_observer_autorun = Tracker.autorun =>
      count = @getSubscribedUnreadChannelsCount() or 0

      if count > 0
        APP.page_title_manager.setPrefix("(#{count})")
      else
        APP.page_title_manager.setPrefix("")

      return

    @onDestroy =>
      count_observer_autorun.stop()

      @releaseRequirementForSubscribedUnreadChannelsCountSubscription()

    return

  _setupReceivedMessagesSoundNotification: ->
    @requireSubscribedUnreadChannelsCountSubscription()

    getCountFromSubscription = =>
      # will be null if subscription isn't ready, a number otherwise.
      return @getSubscribedUnreadChannelsCount()

    _local_storage_key = "received-messages-sound-notification-count-cache"
    getCurrentKnownCount = ->
      # Will return null if we can't determine current count
      return parseInt(localStorage.getItem(_local_storage_key), 10)

    setCurrentKnown = (new_count) ->
      # new_count should be null, if count can't be determined, in such case, we won't set it to the
      # local storage

      if new_count?
        localStorage.setItem(_local_storage_key, new_count)

      return

    ping_audio = new Audio("/packages/justdoinc_justdo-chat/media/notification.ogg")
    ping = ->
      # console.log "XXX PING!"
      ping_audio.play()

      return

    # Init current known count
    setCurrentKnown(getCountFromSubscription())

    # Prevent user initiated requests to set a task as read from causing a notification sound.
    @on "pre-set-channel-unread-state-request", userUnreadStateChangesListener = (channel_type, channel_identifier, new_state) ->
      if new_state == true
         # User requested a task to be marked as unread, increase the current known count by 1
         # so when the server will report count increased, we will have that number already and
         # will ignore it
        if (current_known_count = getCurrentKnownCount())? # Only if we have a known count
          # Increase count to avoid ping in other tabs

          # console.log "XXX Increase count to avoid ping in other tabs"
          setCurrentKnown(current_known_count + 1)

      return

    current_required_ping_timeout = null
    clearCurrentRequiredPingTimeout = ->
      if current_required_ping_timeout?
        clearTimeout current_required_ping_timeout   

      current_required_ping_timeout = null

      return
    server_count_observer_autorun = Tracker.autorun ->
      clearCurrentRequiredPingTimeout() # clear existing-non-executed ping timeout, avoid multiple notifications, in short period of time.

      server_count = getCountFromSubscription()

      if not server_count?
        # Subscription isn't ready, do nothing.

        return

      current_known_count = getCurrentKnownCount()

      # console.log "XXX CHECK IF PING NEEDED", server_count, current_known_count
      if not (current_known_count? and server_count > current_known_count)
        # console.log "XXX DONT PING NOT HIGHER COUNT, OR PREVIOUS, DIDN'T EXIST"

        # Immediately set current known count without ping

        if server_count != current_known_count
          setCurrentKnown(server_count)
      else
        # We had a known count, and the new count reported from the server is bigger.
        if JustdoHelpers.isTabVisible()
          # Immediately set current known count without ping

          # console.log "XXX DONT PING WE ARE ON WINDOW"

          setCurrentKnown(server_count)
        else
          # Wait random time within the next second, ping if after the wait, the
          # window is still not focused and a newly fetched currently known count
          # is still smaller from the server count.

          min = 0
          max = 1000
          random_time_to_wait = Math.floor(Math.random() * (max - min) + min)

          current_required_ping_timeout = setTimeout ->
            server_count = getCountFromSubscription()
            current_known_count = getCurrentKnownCount()

            if JustdoHelpers.isTabVisible()
              # Window is focused now, set current known without ping
              setCurrentKnown(server_count)

              # console.log "XXX TAB BECAME VISIBLE, DON'T PING"
            else
              if current_known_count? and server_count > current_known_count
                ping()

                setCurrentKnown(server_count)
              # else
              #   # Ping isn't required any longer
              #   console.log "XXX Ping isn't required any longer"

            clearCurrentRequiredPingTimeout()
          , random_time_to_wait

          # console.log "XXX WAIT #{random_time_to_wait} AND PING"
      return


    @onDestroy =>
      server_count_observer_autorun.stop()

      @removeListener "pre-set-channel-unread-state-request", userUnreadStateChangesListener

      @releaseRequirementForSubscribedUnreadChannelsCountSubscription()

    return

  _setupBottomWindows: ->
    @_justdo_chat_bottom_windows_manager = new JustdoChatBottomWindowsManager
      justdo_chat: @

    @onDestroy =>
      @_justdo_chat_bottom_windows_manager.destroy()

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

        @_time_current_recent_activity_publication_established = new Date()
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

  # To avoid delay in consecutive requests to get the recent activity publication,
  # in cases such as that of the recent activity dropdown reopening in a short
  # timespan, we don't stop the publication immediately when
  # @stopChannelsRecentActivityPublication() is called, but instead we delay the stop.
  #
  # If another request to get the recent activity publication will be received
  # during the delay time, we will cancel the request to stop the publication.

  _time_current_recent_activity_publication_established: null

  _channel_recent_activity_publication_stop_delay_ms: 1000 * 60 * 5 # 5 mins
  _current_delayed_request_to_stop_channel_recent_activity_publication: null

  # We force refresh of the recent activity publication, in the form of
  # actual stop, and resubscription when @_time_current_recent_activity_publication_established
  # is older than @_max_recent_activity_publication_age .
  #
  # We perform the refresh when @stopChannelsRecentActivityPublication is called
  # before setting up the stop delay timeout.
  #
  # We do it here and not under the @requestSubscribedChannelsRecentActivity()
  # since the publication sends augmented data about the recent activity items
  # (projects, users, tasks detals, etc.) that isn't reactive. If we will establish
  # a new subscription before stoping the existing one (the approach we use for
  # example for the incremental load (increase limit) that relies on the DDP mergebox
  # to not send docs the user already have), it is assumed (not tested),
  # that we will run into issues with the DDP's merge box that won't resend docs ids
  # that already exists in the open publication, and the updated version of the
  # augmented docs won't be received by the user (and they are all the point we
  # want to refresh the subscription for to begin with).
  #
  # If we would refresh in this fashion (full stop, and resubscription) on
  # @requestSubscribedChannelsRecentActivity() the user will experience
  # interference (data will disappear and show again).
  #
  # By doing it here, we avoid that issue, but we potentially 'waste' a request to recent
  # activity subscription, that might never be used.
  _max_recent_activity_publication_age: 1000 * 60 * 5 # 5 mins

  stopChannelsRecentActivityPublication: (_allow_keep_alive=true) ->
    if not @_subscribed_channels_recent_activity_subscription?
      # Nothing to stop...

      return

    @_cancelDelayedRequestToStopChannelRecentActivityPublication()

    if not _allow_keep_alive
      @_subscribed_channels_recent_activity_subscription.stop() # we check existence above
      @_subscribed_channels_recent_activity_subscription = null
      @_subscribed_channels_recent_activity_subscription_dep.changed()

      @_time_current_recent_activity_publication_established = null

      @logger.debug("Channels recent activity subscription stopped")

      return

    if JustdoHelpers.getDateMsOffset(-1 * @_max_recent_activity_publication_age) > @_time_current_recent_activity_publication_established
      # The existing publicatino, reached its max allowed age refresh it (read comment above @_max_recent_activity_publication_age)
      @stopChannelsRecentActivityPublication(false) # Stop the existing publication.
      @requestSubscribedChannelsRecentActivity({additional_recent_activity_request: false})

      @logger.debug("Channels recent activity subscription refreshed")

    @_current_delayed_request_to_stop_channel_recent_activity_publication = setTimeout =>
      @stopChannelsRecentActivityPublication(false)
    , @_channel_recent_activity_publication_stop_delay_ms

    return

  _cancelDelayedRequestToStopChannelRecentActivityPublication: ->
    if @_current_delayed_request_to_stop_channel_recent_activity_publication?
      clearTimeout @_current_delayed_request_to_stop_channel_recent_activity_publication
      @_current_delayed_request_to_stop_channel_recent_activity_publication = null
    
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

    @_cancelDelayedRequestToStopChannelRecentActivityPublication()

    options = _.extend {}, {
      initial_messages_to_request: 10
      additional_messages_to_request: 30
      additional_recent_activity_request: true # If set to true, we assume that the UI already presents
                                               # activity from that publication to the user, and the
                                               # user wants additional entries.
                                               #
                                               # If set to false, we assume that the presentation of recent
                                               # activity just started (e.g. click on the recent activity button)
                                               # we might have a lingered subscription already*, thanks to which,
                                               # recent activity is already presented to the user, or the user
                                               # is now in the wait for the subscription load.
                                               #
                                               # * See @stopChannelsRecentActivityPublication() comments
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
      if not options.additional_recent_activity_request
        @logger.debug "Channel subscription already established"

        return

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

  requireSubscribedUnreadChannelsCountSubscription: ->
    if @_resources_requiring_subscribed_unread_channels_count_subscription_count == 0
      @_subscribed_unread_channels_count_subscription =
        @subscribeSubscribedUnreadChannelsCount()

    @_resources_requiring_subscribed_unread_channels_count_subscription_count += 1

    return @_subscribed_unread_channels_count_subscription

  releaseRequirementForSubscribedUnreadChannelsCountSubscription: ->
    @_resources_requiring_subscribed_unread_channels_count_subscription_count -= 1

    if @_resources_requiring_subscribed_unread_channels_count_subscription_count == 0
      @_subscribed_unread_channels_count_subscription.stop()

    return

  getSubscribedUnreadChannelsCount: ->
    # Note, you must ensure a subscription is available to you by calling:
    # @requireSubscribedUnreadChannelsCountSubscription() that returns a subscription object for you
    # do not stop that subscription when you don't need it any longer, call:
    # @releaseRequirementForSubscribedUnreadChannelsCountSubscription() .

    # Returns null if we can't determine the count.

    if not (subscribed_unread_channels_count_doc = APP.collections.JDChatInfo.findOne("subscribed_unread_channels_count"))?
      return null

    return subscribed_unread_channels_count_doc.count

  renderDataMessage: (data, bot) ->
    if (bot_info = APP.collections.JDChatBotsInfo.findOne({_id: bot}))?
      if (en_msg_template = bot_info.msgs_types?[data.type]?.rec_msgs_templates.en)?
        return en_msg_template.replace /{{(.*?)}}/g, (m, placeholder) ->
          if (val = data[placeholder])?
            return val
          else
            return ""

    return data

  destroy: ->
    if @destroyed
      @logger.debug "Destroyed already"

      return

    _.each @_on_destroy_procedures, (proc) -> proc()

    @destroyed = true

    @logger.debug "Destroyed"

    return