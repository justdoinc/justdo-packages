helpers = share.helpers

# The communication layer between the server and the client
GridDataCom = (collection) ->
  EventEmitter.call this

  @collection = collection

  @

Util.inherits GridDataCom, EventEmitter

_.extend GridDataCom.prototype,
  subscribeDefaultGridSubscription:  ->
    # subscribeDefaultGridSubscription: (collection, arg1, arg2, ...)
    #
    # Subscribes to the subscription created by GridDataCom.setGridPublication
    # as long as the `name` option didn't change.
    #
    # Arguments that follows the collection argument will be used as the subscription
    # args.
    args = _.toArray(arguments).slice(1)

    args.unshift helpers.getCollectionPubSubName(@collection)

    Meteor.subscribe.apply @, args