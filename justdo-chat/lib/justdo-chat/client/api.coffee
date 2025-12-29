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

    ping_audio = new Audio(JustdoHelpers.getCDNUrl("/packages/justdoinc_justdo-chat/media/notification.ogg"))
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

  stopChannelsRecentActivityPublication: (_allow_keep_alive = true) ->
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

    if not (subscribed_unread_channels_count_doc = APP.collections.JDChatInfo.findOne("subscribed_unread_channels_count", {allow_undefined_fields: true}))?
      return null

    return subscribed_unread_channels_count_doc.count

  # Template helpers for transforming data in bot message templates.
  #
  # Format: {{prop1=field1:prop2=field2,...|helper_name:arg1=x:arg2=y}}
  #
  # - Before the pipe (|): Field mappings in format "prop=field" separated by colons
  #   - "prop" is the property name passed to the helper
  #   - "field" is the field name to extract from the data object
  #   - Multiple field mappings can be specified, separated by colons
  #
  # - After the pipe (|): Helper name and optional static arguments
  #   - Helper name is required
  #   - Static arguments are optional, in format "arg=value" separated by colons
  #   - These are passed as the second argument (args_obj) to the helper
  #
  # Helper signature: (fields_obj, args_obj) ->
  #   - fields_obj: Object containing mapped field values from data
  #   - args_obj: Object containing static arguments from template
  #
  # Examples:
  #   "{{user_id=performed_by|displayName}}" - maps data.performed_by to fields_obj.user_id
  #   "{{state_id=state:project_id=project_id|stateLabel:lang=en}}" - multiple fields with static arg
  #   "{{date=due_date|formatDate}}" - simple field mapping
  #
  data_message_helpers:
    # Convert user ID to display name
    # Supports both single user ID and arrays of user IDs
    # 
    # Fields: user_id (required)
    displayName: (fields, args) ->
      user_id = fields.user_id

      if not user_id?
        return ""

      return JustdoHelpers.displayName user_id

    # Format unicode date string (YYYY-MM-DD) or a date object according to user preferences
    # Fields: date (required)
    formatDate: (fields, args) ->
      date = fields.date

      if not date?
        return "empty"
        
      user_preferred_date_format = JustdoHelpers.getUserPreferredDateFormat()
      if _.isString(date)
        return JustdoHelpers.normalizeUnicodeDateStringAndFormatToUserPreference(date, user_preferred_date_format)
      else
        return moment(date).format(user_preferred_date_format)

    # Returns task seqId with hash prefix, and the task title if it exists in minimongo.
    # Note that we return in this format: "#seq_id (title)" instead of using `JustdoHelpers.taskCommonName`
    # since it breaks the hyperlink in the message body.
    # 
    # Fields: task_id (required), seq_id (required, used as fallback if task_id is not found in minimongo)
    # Args: ellipsis (optional, defaults to 40 characters)
    taskCommonName: (fields, args) ->
      task_id = fields.task_id
      seq_id = fields.seq_id
      ellipsis = args.ellipsis or 40

      if (task_doc = APP.collections.Tasks.findOne(task_id, {fields: {seqId: 1, title: 1}}))?
        # seqId should always be the same, but we ensure to use the one from the minimongo to be safe.
        seq_id = task_doc.seqId
        title = task_doc.title

      ret = "##{seq_id}"
      if not _.isEmpty(title)
        ret += " (#{JustdoHelpers.ellipsis(title, ellipsis)})"

      return ret

    # Get field label from schema
    # Fields: field_id (required)
    # Args: lang (optional, defaults to JustdoI18n.default_lang)
    fieldLabel: (fields, args) ->
      field_id = fields.field_id
      lang = args.lang or JustdoI18n.default_lang

      if (gc = APP.modules.project_page.gridControl())?
        schema = gc.getSchemaExtendedWithCustomFields()
      else
        schema = APP.collections.Tasks.simpleSchema()._schema

      if not (field_def = schema[field_id])?
        # If we can't find the field definition in the schema, return the field id
        return field_id

      return TAPi18n.__ field_def.label_i18n, {}, lang

    # Get state label from schema or project custom states
    # Fields: state_id (required), project_id (required)
    # Args: lang (optional, defaults to JustdoI18n.default_lang)
    stateLabel: (fields, args) ->
      state_id = fields.state_id
      project_id = fields.project_id
      lang = args.lang or JustdoI18n.default_lang

      if (gc = APP.modules.project_page.gridControl())?
        schema = gc.getSchemaExtendedWithCustomFields()
      else
        schema = APP.collections.Tasks.simpleSchema()._schema

      state_grid_values = schema.state.grid_values
      if not (state_def = state_grid_values[state_id])?
        # If we can't find the state in the schema, try to get it from the project doc
        # First try to find the state in the custom states
        project_doc = APP.collections.Projects.findOne(project_id, {fields: {conf: 1}})
        if not (state_def = _.find(project_doc?.conf?.custom_states, (def) -> def.state_id is state_id))?
          # If we can't find the state in the custom states, try to get it from the removed custom states
          state_def = _.find(project_doc?.conf?.removed_custom_states, (def) -> def.state_id is state_id)

      label_i18n = state_def?.txt_i18n or state_def?.txt

      if not label_i18n?
        # If we really can't find the state in the project doc, return the state id
        return state_id

      return TAPi18n.__ label_i18n, {}, lang

  # Parse a placeholder string in the format: prop1=field1:prop2=field2,...|helper_name:arg1=x:arg2=y
  # Returns: { fields_mapping: {prop: field, ...}, helper_name: string, args: {arg: value, ...} }
  parseDataMessageHelperString: (placeholder) ->
    KEY_VAL_PAIR_DELIMITER = ":"
    KEY_VAL_DELIMITER = "="

    result =
      fields_mapping: {}
      helper_name: null
      args: {}

    # Split by pipe to separate fields from helper
    pipe_parts = placeholder.split JustdoChat.data_message_helper_delimiter

    if pipe_parts.length < 2
      @logger.warn "Invalid placeholder format (missing helper): \"#{placeholder}\""
      return

    parseDataMessageHelperArgs = (helper_args_str) ->
      helper_args = {}
  
      for arg in helper_args_str.split KEY_VAL_PAIR_DELIMITER
        arg = arg.trim()
        if _.isEmpty arg
          continue
  
        if not arg.includes KEY_VAL_DELIMITER
          @logger.warn "Invalid argument format (missing #{KEY_VAL_DELIMITER}): \"#{arg}\" in \"#{helper_args_str}\""
          return
  
        [key, value] = arg.split KEY_VAL_DELIMITER
        key = key.trim()
        value = value.trim()
  
        helper_args[key] = value
  
      return helper_args

    # Parse field mappings (prop=field:prop=field:...)
    fields_part = pipe_parts[0].trim()
    result.fields_mapping = parseDataMessageHelperArgs(fields_part)

    # Parse helper and arguments (helper_name:arg1=val1:arg2=val2:...)
    helper_parts = pipe_parts[1].trim().split KEY_VAL_PAIR_DELIMITER
    
    # Extract helper name from the first part
    result.helper_name = helper_parts.shift()
    if _.isEmpty(result.helper_name)
      @logger.warn "Invalid helper format (missing helper name): \"#{placeholder}\""
      return

    if not _.isEmpty(helper_parts)
      # Convert the args array back to string so that we can pass it to parseDataMessageHelperArgs 
      helper_args = helper_parts.join KEY_VAL_PAIR_DELIMITER
      # Parse static arguments
      result.args = parseDataMessageHelperArgs helper_args

    return result

  renderDataMessage: (data, bot) ->
    data = _.extend {}, data

    if (bot_info = APP.collections.JDChatBotsInfo.findOne({_id: bot}))?
      # If msg is from bot and type is i18n-message, return msg based on i18n_key and i18n_options
      if data.type is "i18n-message"
        return TAPi18n.__ data.i18n_key, data.i18n_options

      # If msg is from bot and type isn't i18n-message, return the en message and replace any placeholders with variables inside data
      # Format: {{prop1=field1:prop2=field2,...|helper_name:arg1=x:arg2=y}}
      if (en_msg_template = bot_info.msgs_types?[data.type]?.rec_msgs_templates.en)?
        return en_msg_template.replace /{{(.*?)}}/g, (m, placeholder) =>
          # Parse the placeholder
          if placeholder.includes JustdoChat.data_message_helper_delimiter
            parsed = @parseDataMessageHelperString(placeholder)

            if not parsed?
              return ""

            if not parsed.helper_name
              @logger.warn "No helper specified in placeholder: \"#{placeholder}\""
              return ""

            # Build fields object by extracting values from data
            fields_obj = {}
            for prop_name, field_name of parsed.fields_mapping
              fields_obj[prop_name] = data[field_name]

            # Get the helper and apply it
            helper = @data_message_helpers?[parsed.helper_name]
            if not helper?
              @logger.warn "Unknown bot message template helper \"#{parsed.helper_name}\""
              return ""

            val = helper(fields_obj, parsed.args)
          else
            val = data[placeholder]

          if val?
            return val
          else
            return ""

    # Return as-is if message isn't from bot.
    return data

  linkTaskId: (msg_body) ->
    return msg_body.replace /(^|\s|\W)#([0-9]{1,6})(?=($|[\s.,;]))/g, (match, spaces, task_id) ->
      task_seq_id = parseInt(task_id, 10)

      return """#{spaces}<a class="task-link" href="#">##{task_id}</a>"""

  isFileTypeInlinePreviewable: (mime_type) ->
    category = JustdoHelpers.mimeTypeToPreviewCategory mime_type
    is_previewable_by_justdo_chat = category in JustdoChat.inline_previewable_file_categories

    return is_previewable_by_justdo_chat

  destroy: ->
    if @destroyed
      @logger.debug "Destroyed already"

      return

    _.each @_on_destroy_procedures, (proc) -> proc()

    @destroyed = true

    @logger.debug "Destroyed"

    return