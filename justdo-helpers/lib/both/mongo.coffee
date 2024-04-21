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

  fieldsArrayToExclusiveFieldsProjection: (fields_arr) ->
    res = {}

    for field_id in fields_arr
      res[field_id] = 0

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

  getFieldsInvolvedInUpdateOperation: (modifier) ->
    # We know for sure that TasksCollectionConstructor.ALLOWED_UPDATE_OPERATIONS are the
    # only possible operators, since
    # justdo-tasks-collections-manager/lib/both/tasks-collection-constructor-and-initiator.js
    # will throw an exception otherwise.

    fields = new Set()

    for allowed_operator of TasksCollectionConstructor.ALLOWED_UPDATE_OPERATIONS
      if modifier[allowed_operator]?
        for field_id of modifier[allowed_operator]
          fields.add field_id

    return Array.from(fields)

_mock_collections_cache = {}
_.extend JustdoHelpers,
  getCollection2Simulator: (collection, cb) ->
    # Calls cb with a mock collection of collection with the same Schema applied, for the purpose of
    # studying the effect of collection2 Schemas without runnign the query on the actual DB.
    #
    # On the client side, see also: JustdoHelpers.fakeMongoUpdate()

    # Returns the cb result, assumes cb is synchronous
    if not (collection_schema = collection._c2?._simpleSchema)?
      # Nothing to do, don't even produce a cache
      return cb?(new Mongo.Collection(null))

    if not (mock_collection = _mock_collections_cache[collection._mock_collection_id])?
      collection._mock_collection_id = Random.id()
      mock_collection = _mock_collections_cache[collection._mock_collection_id] = new Mongo.Collection(null)

      refresh_schema = true

    else if (collection_schema._schemaKeys.length != mock_collection._c2._simpleSchema._schemaKeys.length)
      # This isn't bulletproof by any means, my assumption is that it is unlikely that schema
      # keys are removed or edited (Daniel C.)
      refresh_schema = true

    if refresh_schema is true
      # Recreate the mock collection, to avoid merging the updated schema with the old
      mock_collection = _mock_collections_cache[collection._mock_collection_id] = new Mongo.Collection(null)
      mock_collection.attachSchema(collection_schema._schema)

    err = undefined
    try
      cb_result = cb?(mock_collection)
    catch _err
      err = _err
    finally
      # We catch, so we will always clean the mock collection properly.
      # Clean the mock collection
      mock_collection.remove {}

      if err?
        throw err

    return cb_result
