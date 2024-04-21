_.extend JustdoHelpers,
  requireLogin: (endpoint_this, self=null) ->
    # Throw an error if pub/method was called with no
    # userId.
    #
    # endpoint_this is the publication/method this
    #
    # self is an optional instance of a package based
    # on the justdo-packages-skeleton

    error_type = "login-required"
    if not endpoint_this.userId?
      if self?._error?
        throw self._error error_type

      else
        throw new Meteor.Error "login-required"

    return

  customizedCursorPublish: (publish_this, cursor, safe_options, restricted_options) ->
    # Gives more control to the way a cursor is being published.
    #
    # If we find that no customization is required we will
    # return the cursor as is, for you to return it.
    #
    # If customizations are required we will return undefined
    # and the actual publication will be done with the low-level
    # ddp functions, in such a case you don't need to return
    # anything.
    #
    # XXX Important: This function, at the moment, is not designed
    # for multiple cursors publications (need to manage 'ready'
    # message correctly).
    #
    # Arguments
    # ---------
    #
    # publish_this: the publish `this`
    # cursor: The cursor to publish
    #
    # safe_options - these options you can allow users of the
    # subscription to provie over ddp from the client:
    #
    #   * custom_col_name: "CollectionName" 
    #     # Tells ddp to publish the cursor under a different
    #     # collection name.
    #     # Will be ignored if equal to real collection name.
    #   * label: "label"
    #     # Does 2 things:
    #     # (1) A "_label" field will be added to all published
    #     #     documents with the value given.
    #     # (2) In addition the id of all documents will be altered
    #     #     to: "#{original_id}::label". (we must do that to
    #     #     prevent collisions if same doc returned for 2 subscriptions
    #     #     with different labels.
    #     #
    #     # Purpose:
    #     # We use label to distinguish between the outputs of 2
    #     # different subscriptions that receives documents
    #     # to same pseudo-collection.
    #
    # restricted_options: these options *must* be set in the server side
    #
    #   * data_maps: If provided, should be an object, or an array of objects of the
    #     form:
    #
    #     {
    #       dependent_field: "" # The field that the map is based on,
    #       map: (id, data) -> {} # The map operation 
    #       recalc_interval_secs: Number/null/undefined # The interval in seconds to recalc map
    #                                                   # if set to 0 or null/undefined, ignored
    #     }
    #
    #     We will call the map method with the added/changed(id, data) before sending
    #     data with the added/changed ddp messages, to allow you to augment/change
    #     the data.
    #
    #     map will be called only if the dependent_field is part of the added/changed data.
    #     
    #     The changes you want to perform should be returned as an object of new/changed
    #     fields. We will apply these changes with _.extend() .
    #
    #     If null/undefined is returned by map, we will keep data as-is.
    #
    #     Notes:
    #
    #     * Though we allow providing array of data_maps, at the moment only single
    #       data map is implemented! 
    #
    #     * Items that depends on the _id/id field will only be triggered on "added"
    #       and not on every "changed". 
    #
    #     * We encourage you to prefix with _ augmented fields.
    #
    #     * The reasons why we require dependent_field to be specified are as follow:
    #       * We want to make it clear that only one field can be the base for map
    #         at the moment due to the nature of the observeChanges() method on which
    #         we are implementing the customization process of this function. (note that
    #         by using observe() instead we could have lifted this requirement, but that would
    #         make implementation a bit more complex).
    #       * If recalc_interval_secs below is set, we must know who is the
    #         dependent_field, and therefore, we decided, that it worth having consistent
    #         api for case that recalc_interval_secs is set and case it isn't.
    #
    #     * To learn more about the data provided to the map check the data provided
    #       for the added/changed callbacks of observeChanges().
    #     * Do not change data in data_maps maps methods! Return the changes object
    #

    #
    # Usage example
    # -------------
    #
    # Meteor.publish "pubName", ->
    #   cursor = col.find()
    #
    #   return customizedCursorPublish(@, cursor, {label: "label", custom_col_name: "ColName"})

    if not safe_options?
      safe_options = {}

    if not restricted_options?
      restricted_options = {}

    real_collection_name = JustdoHelpers.getCollectionNameFromCursor(cursor)

    if not _.isEmpty(safe_options)
      # Create a new obj, only with recognized safe_options
      # That protects the original safe_options obj from editing
      # as well.
      safe_options = _.pick safe_options, ["custom_col_name", "label"] 

      check safe_options.custom_col_name, Match.Maybe(String)
      check safe_options.label, Match.Maybe(String)

      # Remove redundant safe_options
      if (custom_col_name = safe_options.custom_col_name)?
        if real_collection_name?
          if real_collection_name == custom_col_name
            delete safe_options.custom_col_name

    if _.isEmpty(safe_options) and _.isEmpty(restricted_options)
      # If after cleaning emptied both options objs are empty, just return the cursor
      return cursor

    # Merge the cleaned safe_options and restricted_options into options
    options = _.extend {}, safe_options, restricted_options

    #
    # Custom publication
    #
    {custom_col_name, label, data_maps} = options

    # Find target_col_name to use for the publication
    if not real_collection_name? and not custom_col_name?
      throw Meteor.Error "unknown-collection-name", "Can't publish the cursor, can't determine target collection name" 
    target_col_name = custom_col_name or real_collection_name

    # Publish
    if not label?
      getItemId = (id) ->
        return id
    else
      getItemId = (id) ->
        return "#{id}::#{label}"

    if not data_maps? or _.isEmpty(data_maps)
      # Do nothing if there's no data_maps or empty data_maps
      dataMapsExtensions = -> return
    else
      if not _.isArray data_maps
        data_maps = [data_maps]

      check data_maps, [{
          dependent_field: String
          map: Function
          recalc_interval_secs: Match.Maybe(Number)
        }]

      if data_maps.length > 1
        throw new Error "We don't support multiple data_maps at the moment"

      data_map = data_maps[0]

      {dependent_field, map, recalc_interval_secs} = data_map

      if dependent_field == "_id"
        # Normalize, so we won't need to check both cases.
        dependent_field = "id"

      if not recalc_interval_secs? or recalc_interval_secs == 0
        # The difference if we got recalc_interval_secs set is big enough to
        # have dataMapsExtensions implemented twice
        dataMapsExtensions = (id, data, action) ->
          if action == "removed"
            # Nothing to do for removed
            return

          if data[dependent_field]? or
                (dependent_field == "id" and action == "added")
            # id is not part of data, and is always existing, but we will perform
            # map only on "added" if we depend on it
            if (new_data = map(id, data))?
              _.extend data, new_data # note in-place change

          return
      else
        throw new Error "data_map.recalc_interval_secs isn't implemented yet"

    tracker = cursor.observeChanges
      added: (id, data) ->
        if label?
          # If we got a label for this subscription, add the _label
          # field.
          data._label = label

        dataMapsExtensions(id, data, "added")

        publish_this.added target_col_name, getItemId(id), data

      changed: (id, data) ->
        dataMapsExtensions(id, data, "changed")

        publish_this.changed target_col_name, getItemId(id), data

      removed: (id) ->
        dataMapsExtensions(id, undefined, "removed")

        publish_this.removed target_col_name, getItemId(id)

    publish_this.onStop ->
      tracker.stop()

    publish_this.ready()

    # Since we manage the publication, we don't return the cursor
    # to avoid Metoer from publishing it as well.
    return undefined

  getCollectionNameFromCursor: (cursor) ->
    return cursor._cursorDescription?.collectionName

  applyAdditionalSubscriptionArgsCallbacks: (args, added_callbacks, options) ->
    # Edit args in place!
    #
    # Args should be an array of *all* the arguments provided to the original subscription.
    #
    # added_callbacks is an optional object with the following optional properties:
    #
    #   onReady # will be performed in addition to the original args onReady callback (if there was one)
    #   onStop # will be performed in addition to the original args onStop callback (if there was one)
    # 
    # options is an optional object with the following optional properties:
    #
    #   do_additional_onReady_before_original # Boolean, optional, default: true (relevant only if added_callbacks.onReady provided)
    #   do_additional_onStop_before_original # Boolean, optional, default: true (relevant only if added_callbacks.onStop provided)

    options = _.extend {do_additional_onReady_before_original: true, do_additional_onStop_before_original: true}, options

    # Find existing callbacks, if any, and prepare them for extension
    callbacks = {}

    last_arg_need_replacement = false
    if (prev_last_arg = _.last args)?
      if _.isFunction prev_last_arg
        callbacks.onReady = prev_last_arg

        last_arg_need_replacement = true
      else if _.isObject(prev_last_arg) and (("onStop" of prev_last_arg) or ("onReady" of prev_last_arg))
        _.extend callbacks, prev_last_arg

        last_arg_need_replacement = true

    if (additional_onReady = added_callbacks.onReady)?
      original_onReady = callbacks.onReady
      callbacks.onReady = ->
        if options.do_additional_onReady_before_original
          additional_onReady.apply(@, arguments)

        # Call original onReady, if any
        if _.isFunction original_onReady
          original_onReady.apply(@, arguments)

        if not options.do_additional_onReady_before_original
          additional_onReady.apply(@, arguments)

        return

    if (additional_onStop = added_callbacks.onStop)?
      original_onStop = callbacks.onStop
      callbacks.onStop = ->
        if options.do_additional_onStop_before_original
          additional_onStop.apply(@, arguments)

        # Call original onStop, if any
        if _.isFunction original_onStop
          original_onStop.apply(@, arguments)

        if not options.do_additional_onStop_before_original
          additional_onStop.apply(@, arguments)

        return

    # Add our extended callbacks to args
    if last_arg_need_replacement
      args[args.indexOf(prev_last_arg)] = callbacks
    else
      args.push callbacks

    return

  replaceDdpSubscriptionParamsToBeUsedInReconnection: (publication_name, cb) ->
    # cb will get the arguments: (err, params)
    #
    # err should be undefined if no issue encountered, err will be true if:
    #
    #   1. We couldn't find an open subscription to publication_name
    #   2. There's more than one open subscription to publication_name, we don't
    #      support that case at the moment (not because we can't, but because we
    #      don't want to consider at the moment potential side-effect Daniel C.)
    #
    # You are expected to return the list of subscription params to replace the current params with,
    # (You can edit the received params in place, or return a new one. Results for editing in place
    # might be unexpected, so better return a new one Daniel C.)
    if not _.isObject(open_subscriptions = Meteor.connection._subscriptions)
      # To avoid unnoticed issues, if we can't find the above, assume something changed radically
      # and report about it with alert (not only console log)
      alert("Meteor.connection._subscriptions is not an object")

    found = false
    subscription = null
    for subscription_id, subscription_def of open_subscriptions
      if subscription_def.name == publication_name
        if found
          console.error "replaceDdpSubscriptionParamsToBeUsedInReconnection: More than one open subscription found for publication #{publication_name}, this isn't supported at the moment."

          cb(true)

          return

        found = true
        subscription = subscription_def

    if not found
      console.error "replaceDdpSubscriptionParamsToBeUsedInReconnection: couldn't find any open subscription to publication #{publication_name}"

      cb(true)

      return

    new_params = cb(undefined, subscription.params)

    subscription.params = new_params

    return

  getLastReceivedDdpMessageTime: ->
    return Meteor.connection.last_ddp_message_date_obj?.getTime()

  getLastReceivedDdpMessageServerTime: ->
    if not (last_ddp_message_date_obj = Meteor.connection.last_ddp_message_date_obj)?
      return undefined # Will happen only if no ddp message ever received

    return TimeSync.getServerTime(last_ddp_message_date_obj)

  getLastReceivedDdpMessageServerTimeOrNow: ->
    if not (last_received_ddp_message_server_time = JustdoHelpers.getLastReceivedDdpMessageServerTime())?
      # Will be undefined only if no message ever received, so the following is highly unlikely to ever happen
      last_received_ddp_message_server_time = TimeSync.getServerTime()

    return last_received_ddp_message_server_time
