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

  requireProjectTasksSubscription: (project_id) ->
    self = @

    # Returns .ready() which is a proxy to the subscription .ready()
    # and .stop() which release the need for the subscription, once all the resources
    # that called requireProjectTasksSubscription() calls stop() or, if reactive resources,
    # get invalidated, we unsubscribe the project tasks subscription.
    self.logger.debug "Subscribe #{project_id}"

    if not required_tasks_subscriptions_count[project_id]?
      required_tasks_subscriptions_count[project_id] = 0
    required_tasks_subscriptions_count[project_id] += 1

    if project_id of open_tasks_subscriptions_handles
      handle = open_tasks_subscriptions_handles[project_id]
    else
      options = {project_id: project_id, respect_exclude_from_tasks_grid_pub_directive: false}

      if project_id of tasks_subscription_last_sync_time
        project_last_sync_time = tasks_subscription_last_sync_time[project_id]

        options.sync = project_last_sync_time

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

                    new_params = [options]

                    self.logger.debug "Update open subscription sync option for followup reconnection #{sub_name}"

                    return new_params

            return

          onStop: (err) ->
            if err?
              releaseRequirement() # call releaseRequirement, so it won't be able to be called again, and to clear the required_tasks_subscriptions_count for this project_id
            else
              tasks_subscription_last_sync_time[project_id] = getCurrentSyncTimeWithSafetyDelta()

            delete open_tasks_subscriptions_handles[project_id]

            return

      open_tasks_subscriptions_handles[project_id] = handle

    releaseRequirement = _.once ->
      required_tasks_subscriptions_count[project_id] -= 1

      if required_tasks_subscriptions_count[project_id] == 0
        delete required_tasks_subscriptions_count[project_id]

        handle?.stop()

        meteor_connection_tracker?.stop()

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
