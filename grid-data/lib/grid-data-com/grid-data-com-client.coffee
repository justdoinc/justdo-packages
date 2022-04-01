helpers = share.helpers

# The communication layer between the server and the client
GridDataCom = (collection) ->
  EventEmitter.call this

  @collection = collection

  return @

Util.inherits GridDataCom, EventEmitter

_.extend GridDataCom.prototype,
  countItems: (options, cb) ->
    Meteor.call GridData.helpers.getCollectionMethodName(@collection, "countItems"), options, (err, items_count) ->
      helpers.callCb cb, err, items_count

      return

    return

  loadDefaultGridFromHttpPreReadyPayload: (subscription_options, http_options, cb) ->
    APP.justdo_ddp_extensions.loadHttpPreReadyPayloadToMiniMongoStore "tasks_grid_um",
      [subscription_options, {"unmerged_pub_ddp_extensions_version": 1, "init_payload_raw_cursors_mode": true, "skip_id_transcoding": true}], http_options, cb

    return

  subscribeDefaultGridSubscription: (subscription_options, subscription_callbacks) ->
    # subscribeDefaultGridSubscription: (arg1, arg2, ..., subscription_callbacks)
    #
    # Subscribes to the subscription created by GridDataCom.setGridPublication
    # as long as the `name` option didn't change.
    #
    # Arguments that follows the collection argument will be used as the subscription
    # args.

    args = [
      helpers.getCollectionUnmergedPubSubName(@collection),
      subscription_options,
      {unmerged_pub_ddp_extensions_version: 1},
      subscription_callbacks
    ]

    return APP.justdo_ddp_extensions.unclearedUnmergedSubscribe.apply APP.justdo_ddp_extensions, args

  subscribeTasksAugmentedFields: (args...) ->
    args.unshift "tasks_augmented_fields"

    return Meteor.subscribe.apply Meteor, args

# Add a shortcut to helpers
GridDataCom.helpers = helpers