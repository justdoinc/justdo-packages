if not _.isObject(Meteor.connection._subscriptions)
  # To avoid unnoticed issues, if we can't find the above, assume something changed radically
  # and report about it with alert
  alert("Meteor.connection._subscriptions is not an object")

# tasks_subscription_last_sync_time keys are projects_ids to which we had subscription/s before,
# to which, right now, we have no subscriptions at all.
#
# If a new tasks subscription will be created for these projects, it'll be created with the 
# sync option set to the last time we had a subscription, minus sync_safety_delta_ms.
tasks_subscription_last_sync_time = {}
sync_safety_delta_ms = 2 * 60 * 1000 # 2 minutes
# open_tasks_subscriptions_handles keys are projects ids, values are the subscriptions
# handles
open_tasks_subscriptions_handles = {}
# required_tasks_subscriptions_count counts the requests for @requireProjectTasksSubscription
# calls that haven't been stopped or invalidated.
# Keys are projects ids values is the count. When value reach 0 we remove the key and unsubscribe
# the respective handle under open_tasks_subscriptions_handles.
required_tasks_subscriptions_count = {}

getCurrentSyncTimeWithSafetyDelta = -> new Date(TimeSync.getServerTime() - sync_safety_delta_ms)

_.extend Projects.prototype,
  _setupSubscriptions: ->
    @_subscribeUserProjects()
    @_subscribeUserGuestProjects()

    return

  _setupProjectRemovalProcedures: ->
    self = @

    self.projects_collection.find({}).observeChanges
      removed: (id) ->
        # Remove from the storage tasks of the removed project.
        self.items_collection._collection.remove({project_id: id})

        delete tasks_subscription_last_sync_time[id]

        return

    return

  getSubscriptionHandle: (name) -> @_subscriptions_handles[name]

  _setSubscriptionHandle: (name, handle) ->
    # Stop existing subscription under same name
    if name of @_subscriptions_handles
      # only if different subscription
      if handle.subscriptionId != @_subscriptions_handles[name].subscriptionId
        @_subscriptions_handles[name].stop()

    @_subscriptions_handles[name] = handle

    return handle

  _subscribeUserProjects: -> @_setSubscriptionHandle "projects", Meteor.subscribe("userProjects", false)

  _subscribeUserGuestProjects: -> @_setSubscriptionHandle "guest_projects", Meteor.subscribe("userProjects", true)

  requireProjectTasksSubscription: (project_id, force_init_payload_over_ddp) ->
    self = @

    # Returns .ready() which is a proxy to the subscription .ready()
    # and .stop() which release the need for the subscription, once all the resources
    # that called requireProjectTasksSubscription() calls stop() or, if reactive resources,
    # get invalidated, we unsubscribe the project tasks subscription.
    self.logger.debug "Subscribe #{project_id}"

    if not required_tasks_subscriptions_count[project_id]?
      required_tasks_subscriptions_count[project_id] = 0
    required_tasks_subscriptions_count[project_id] += 1

    ongoing_http_request_rv = new ReactiveVar(false)

    # State 1: An http-load/subscription of this JustDo is already in-progress/established.
    #          Just use the existing one.
    if project_id of open_tasks_subscriptions_handles
      handle = open_tasks_subscriptions_handles[project_id]
    # State 2: An http-load/subscription isn't in-progress/established.
    else
      # STATE 2.X BEGIN
      options = {project_id: project_id, respect_exclude_from_tasks_grid_pub_directive: true}

      # Two ways to produce an handle in the following State 2.1/2.2

      if not force_init_payload_over_ddp and (project_id not of tasks_subscription_last_sync_time)
        # STATE 2.1 BEGIN

        # State 2.1: We never subscribed before to this JustDo, load first the JustDo using http-load.

        handle = Tracker.nonreactive -> # Run in a nonreactive scope to ensure no reactive resource below affects the caller
          stopped = false
          subscription_handle = null # This will hold the handle from a followup call to requireProjectTasksSubscription
                                     # that will enter state 2.2 following the http init-payload load.

          ready = false
          ready_dep = new Tracker.Dependency()

          deleteFakeHandleFromHandlersRegistry = ->
            delete open_tasks_subscriptions_handles[project_id]
            return

          fake_subscription_handle =
            ready: ->
              ready_dep.depend()

              return ready

            stop: _.once ->
              stopped = true
              
              releaseRequirement() # call releaseRequirement, so it won't be able to be called again, and to clear the required_tasks_subscriptions_count for this project_id
                                   # Note, there's no risk of calling it more than once, it can run only once.

              if not subscription_handle?
                # Only if subscription_handle isn't established yet delete the handler, otherwise,
                # the handler is already the handler of the subscription_handle, and it should
                # be deleted by it (when we'll call subscription_handle.stop() for that case).
                deleteFakeHandleFromHandlersRegistry()
              else
                # If subscription_handle established, pass the request to stop to it.
                subscription_handle.stop()

              return

          ongoing_http_request_rv.set(true)
          self._grid_data_com.loadDefaultGridFromHttpPreReadyPayload options, {max_age: Projects.grid_init_payload_cache_max_age_seconds}, (err, init_payload_sync_id) ->
            ongoing_http_request_rv.set(false)

            failed = false

            if err?
              failed = true

              console.error "FATAL: couldn't load project tasks - falling back to ddp based init-payload retrieval"

              # It is important to show some indication so at least a developer will know this
              # is the cause for the slowness and not a slow internet connection (which might be
              # the first assumption)
              JustdoSnackbar.show
                text: "Loading this JustDo is taking a bit longer than usual, but it should be ready soon"
                duration: 7000

            ready = true
            ready_dep.changed()

            # Even if we got the stop request, set the tasks_subscription_last_sync_time[project_id]
            # so subsequent requests will not get again to State 2.1
            if init_payload_sync_id?
              tasks_subscription_last_sync_time[project_id] = init_payload_sync_id
            else
              if not failed
                # If we didn't fail, and for whatever reason we don't have an init_payload_sync_id
                # use current time - safety delta as the init_payload_sync_id
                #
                # This case is theoretical, and as of writing I can't think of a situation where it might
                # happen. (Daniel C.)
                #
                # If we did fail - we don't want to set tasks_subscription_last_sync_time[project_id]
                # at all, so the ddp subscription will be called without the sync param and will receive
                # the init payload.
                console.warn "loadDefaultGridFromHttpPreReadyPayload returned with no init_payload_sync_id"
                tasks_subscription_last_sync_time[project_id] = new Date(TimeSync.getServerTime() - sync_safety_delta_ms)

            if stopped
              # Stopped already by the user/or as a result of a failure, don't proceed to establish subscription.
              return

            # Initial payload loaded using http, prepare for calling requireProjectTasksSubscription again
            # to establish the ddp subscription with the sync in accordance with the sync value we got
            # in the initial payload.
            
            # Set sync and delete the fake handler so the following request to requireProjectTasksSubscription()
            # will get to State 2.2

            deleteFakeHandleFromHandlersRegistry()

            # COMMENT:REQUIRED_TASKS_SUBSCRIPTIONS_COUNT_MANAGEMENT
            #
            # We subtract 1 from the required_tasks_subscriptions_count[project_id] since the following call to
            # self.requireProjectTasksSubscription(project_id) will increase the count by 1, which means
            # that there'll be 1 extra required_tasks_subscriptions_count for this project id for the same
            # request, that will prevent releaseRequirement to call the handle stop upon call, because it will think
            # there are more resources that need this subscription. This will keep the subscription running
            # forever.
            required_tasks_subscriptions_count[project_id] -= 1

            subscription_handle = self.requireProjectTasksSubscription(project_id, failed) # If failed is true we will force the followup attempt to go through ddp

            return

          return fake_subscription_handle
        # STATE 2.1 END
      else
        # STATE 2.2 BEGIN

        # State 2.2: We subscribed before to this JustDo, re-subscribe assuming the initial payload already received.

        if tasks_subscription_last_sync_time[project_id]?
          # Note, this can happen when force_init_payload_over_ddp is set to true
          # force_init_payload_over_ddp will be set to true, if we failed to obtain the payload over http
          options.sync = tasks_subscription_last_sync_time[project_id] # The if statement we are in ensures tasks_subscription_last_sync_time[project_id] existence

        # If the handle needed by @requireProjectTasksSubscription() created inside a computation
        # we don't want the computation invalidation to stop the subscription for others that might
        # still need it. See below `Tracker.currentComputation?` to see what we are doing in such
        # a case.
        meteor_connection_tracker = null
        handle = Tracker.nonreactive ->
          return self._grid_data_com.subscribeDefaultGridSubscription options,
            onReady: ->
              delete tasks_subscription_last_sync_time[project_id]

              last_state_is_connected = true
              meteor_connection_tracker = Tracker.autorun ->
                if last_state_is_connected != Meteor.status().connected
                  new_state_is_connected = Meteor.status().connected
                  last_state_is_connected = new_state_is_connected

                  if new_state_is_connected == false
                    self.logger.debug "DDP disconnection detected"

                    sub_name = GridDataCom.helpers.getCollectionUnmergedPubSubName(self.items_collection)
                    JustdoHelpers.replaceDdpSubscriptionParamsToBeUsedInReconnection sub_name, (err, existing_params) ->
                      if err?
                        self.logger.error "Couldn't replace subscription params"

                        return

                      options = _.extend {}, existing_params[0] # shallow copy

                      options.sync = getCurrentSyncTimeWithSafetyDelta()

                      existing_params[0] = options

                      self.logger.debug "Update open subscription sync option for followup reconnection #{sub_name}"

                      return existing_params

              return

            onStop: (err) ->
              if err?
                releaseRequirement() # call releaseRequirement, so it won't be able to be called again, and to clear the required_tasks_subscriptions_count for this project_id
              else
                tasks_subscription_last_sync_time[project_id] = getCurrentSyncTimeWithSafetyDelta()

              delete open_tasks_subscriptions_handles[project_id]

              return

        # STATE 2.2 END

      open_tasks_subscriptions_handles[project_id] = handle

      # STATE 2.X END

    releaseRequirement = _.once ->
      release = ->
        required_tasks_subscriptions_count[project_id] -= 1

        if required_tasks_subscriptions_count[project_id] <= 0
          # Search for comment REQUIRED_TASKS_SUBSCRIPTIONS_COUNT_MANAGEMENT above for how negative cases might happen
          required_tasks_subscriptions_count[project_id] = 0

          handle?.stop()

          meteor_connection_tracker?.stop()

        return

      if not (Tracker.nonreactive -> ongoing_http_request_rv.get())
        # If there's no ongoing http request, release right now.
        return release()

      Tracker.nonreactive ->
        Tracker.autorun (c) ->
          # If there is an ongoing http request, wait for it to finish loading,
          # and only then release this will prevent multiple http requests in
          # cases like:
          #
          # a = APP.projects.requireProjectTasksSubscription("z859T82wEmGz7igyx")
          # a.stop()
          # b = APP.projects.requireProjectTasksSubscription("z859T82wEmGz7igyx")
          # b.stop()
          #
          # Critical for slow connections.
          if ongoing_http_request_rv.get() is false
            c.stop()
            release()

          return

      return

    if Tracker.currentComputation?
      Tracker.onInvalidate =>
        releaseRequirement()

        return

    res =
      ready: -> handle.ready()
      stop: -> releaseRequirement()

    return res

  subscribeTasksAugmentedFields: (items_ids_array, fetched_fields_arr, options, cb) ->
    if _.isString items_ids_array
      items_ids_array = [items_ids_array]
    
    if _.isEmpty(items_ids_array)
      fake_res =
        ready: -> true
        stop: -> true

      if _.isFunction(cb)
        cb()
      else if _.isFunction(cb?.onReady)
        cb.onReady()

      return fake_res

    default_options =
      subscribe_sub_tree: false # If set to true, we will subscribe to the entire sub-trees of items_ids_array

    options = _.extend default_options, options

    if not options.subscribe_sub_tree
      return @_grid_data_com.subscribeTasksAugmentedFields({_id: $in: items_ids_array}, {fetched_fields_arr: fetched_fields_arr}, cb)
    else
      if not (gd = APP.modules.project_page?.mainGridControl()?._grid_data)?
        throw new Meteor.Error("Can't load grid data")

      items_to_subscribe_to_set = new Set(items_ids_array)

      for item_id in items_ids_array
        path = gd.getCollectionItemIdPath(item_id)

        gd.each path, (section, item_type, item_obj, item_path) =>
          items_to_subscribe_to_set.add item_obj._id

          return

      items_to_subscribe_to_arr = Array.from(items_to_subscribe_to_set)

      return @_grid_data_com.subscribeTasksAugmentedFields({_id: $in: items_to_subscribe_to_arr}, {fetched_fields_arr: fetched_fields_arr}, cb)
    
    return

  subscribeActiveTaskAugmentedFields: (fetched_fields_arr, cb) ->
    if not (active_item_id = JD.activeItemId())?
      active_item_id = []

    # We still call @subscribeTasksAugmentedFields() so it'll return the fake response and call the cb properly.
    return @subscribeTasksAugmentedFields(active_item_id, fetched_fields_arr, cb)

  activeTaskAugmentedUsersFieldAutoSubscription: ->
    computation = Tracker.autorun =>
      @subscribeActiveTaskAugmentedFields(["users"])

      return

    if Tracker.currentComputation?
      Tracker.onInvalidate =>
        computation.stop()

        return

    return computation
