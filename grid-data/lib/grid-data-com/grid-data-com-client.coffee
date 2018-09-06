helpers = share.helpers

# The communication layer between the server and the client
GridDataCom = (collection) ->
  EventEmitter.call this

  @collection = collection

  return @

Util.inherits GridDataCom, EventEmitter

_.extend GridDataCom.prototype,
  subscribeDefaultGridSubscription: (args...) ->
    # subscribeDefaultGridSubscription: (arg1, arg2, ..., subscription_callbacks)
    #
    # Subscribes to the subscription created by GridDataCom.setGridPublication
    # as long as the `name` option didn't change.
    #
    # Arguments that follows the collection argument will be used as the subscription
    # args.

    args.unshift helpers.getCollectionUnmergedPubSubName(@collection)

    return APP.justdo_ddp_extensions.unclearedUnmergedSubscribe.apply APP.justdo_ddp_extensions, args

# Add a shortcut to helpers
GridDataCom.helpers = helpers