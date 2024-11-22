_.extend JustdoCoreHelpers,
  getCollectionSchema: (collection, options) ->
    # possible options
    #
    # options.without_keys: (Array, optional) if provided, we will exclude from
    #                       the returned SimpleSchema object the keys listed
    simple_schema = collection?.simpleSchema()

    # If no schema existed, on the collection, we can return here.
    if not simple_schema?
      return simple_schema

    # If no options provided, we can return here.
    if not options?
      return simple_schema

    if (without_keys = options.without_keys)?
      keys_to_pick = _.difference(simple_schema._schemaKeys, without_keys)

      simple_schema = simple_schema.pick keys_to_pick

    return simple_schema