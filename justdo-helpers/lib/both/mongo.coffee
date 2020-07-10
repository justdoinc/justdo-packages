_.extend JustdoHelpers,
  fakeMongoUpdate: (collection, selector, modifier, options, callback) ->
    # This should be used only in very rare cases!

    # BE CAREFUL! Collections hooks won't be called for fake updates

    return collection._collection.update selector, modifier, options, callback

  getExistingMongoCollectionStoreObject: (collection_name) ->
    return Meteor.connection._stores[collection_name]

  getExistingMongoCollectionObjectForDDPCollectionName: (collection_name) ->
    return @getExistingMongoCollectionStoreObject(collection_name)?._getCollection()

  fieldsArrayToInclusiveFieldsProjection: (fields_arr) ->
    res = {}

    for field_id in fields_arr
      res[field_id] = 1

    return res

  mongoQueryAddAdditionalRequiredOrStatement: (query, or_array) ->
    # Edits query in place

    if not (existing_or = query.$or)?
      query.$or = or_array

      return query

    delete query.$or
    query.$and = [
      {$or: existing_or},
      {$or: or_array}
    ]

    return query