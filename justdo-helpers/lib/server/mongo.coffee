_.extend JustdoHelpers,
  findOneAndUpdate: (collection, query, update, options) ->
    if not (raw_collection = collection?.rawCollection?())
      throw new Meteor.Error "invalid-argument", "Please provide a valid collection, instead of the rawCollection object."
    
    findOneAndUpdateSynchronous = Meteor.wrapAsync raw_collection.findOneAndUpdate, raw_collection
    APP.justdo_analytics.logMongoRawConnectionOp(collection._name, "findOneAndUpdate", query, update, options)
    return findOneAndUpdateSynchronous query, update, options

  findOneAndUpdateAsync: (collection, query, update, options) ->
    if not (raw_collection = collection?.rawCollection?())
      throw new Meteor.Error "invalid-argument", "Please provide a valid collection, instead of the rawCollection object."
    
    APP.justdo_analytics.logMongoRawConnectionOp(collection._name, "findOneAndUpdate", query, update, options)
    return await raw_collection.findOneAndUpdate query, update, options