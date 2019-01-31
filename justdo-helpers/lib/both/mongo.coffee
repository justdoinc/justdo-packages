_.extend JustdoHelpers,
  fakeMongoUpdate: (collection, selector, modifier, options, callback) ->
    # This should be used only in very rare cases!

    # BE CAREFUL! Collections hooks won't be called for fake updates

    return collection._collection.update selector, modifier, options, callback

  getExistingMongoCollectionStoreObject: (collection_name) ->
    return Meteor.connection._stores[collection_name]

  getExistingMongoCollectionObjectForDDPCollectionName: (collection_name) ->
    return @getExistingMongoCollectionStoreObject(collection_name)?._getCollection()
