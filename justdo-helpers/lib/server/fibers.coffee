Fiber = Npm.require "fibers"

_.extend JustdoHelpers,
  Fiber: Fiber

  runInFiber: (cb) ->
    # Use in cases when Meteor.bindEnvironment can't be used.
    
    if not _.isFunction(cb)
      return

    if @getCurrentFiber()?
      # Already running inside a fiber
      cb()

      return undefined

    fiber = Fiber(cb)

    fiber.run()

    # Explicitly return undefined, the value, from my tests can't be trusted to pass:
    # e.g.
    # When I did:
    # return fiber.run()
    #
    # console.log(JustdoHelpers.runInFiber(function () {return Meteor.users.findOne("ZgYhc8GEnH5aQWiRr")}))
    # returned undefined for existing user.
    #
    # If you want to get the result of the function, use runInFiberAndGetResult instead.
    return undefined

  # THIS IS AN ASYNC/AWAIT FUNCTION
  runInFiberAndGetResult: (cb) ->
    # Usage:
    #
    # await JustdoHelpers.runInFiberAndGetResult(cb)
    #
    # Retruns a promise that resolves with the result of cb() or rejects with an error
    #
    # Note: the following doesn't work (!) probably quirks with the way fibers work
    # runInFiberAndGetResult: (cb) ->
    #   result = undefined
    #
    #   @runInFiber(() ->
    #     result = cb()
    #   )
    #
    #   return result
    return new Promise (resolve, reject) =>
      @runInFiber(() ->
        try
          result = cb()

          process.nextTick(() ->
            resolve(result)
          )
        catch err
          reject(err)
      )

  getCurrentFiber: ->
    return Fiber.current

  requireCurrentFiber: ->
    fiber = @getCurrentFiber()

    if not (fiber = Fiber.current)?
      throw throw new Error("no-fiber")

    return fiber

  fiberYield: ->
    # A shortcut, with which users of JustdoHelpers can avoid requiring fibers

    return Fiber.yield()

  pseudoBlockingRawCollectionInsertInsideFiber: (collection, doc) ->
    fiber = @getCurrentFiber()

    if not (fiber = Fiber.current)?
      throw throw new Error("no-fiber")

    if not doc._id?
      # The _id assigned automatically by mongo follows a different structure then
      # what Meteor's Collection.insert() would have put (Mongo's default uses an ObjectId type
      # instead of string). That interferes later on with the DDP.
      # hence, we set here an _id that follows Meteor's standards
      doc = _.extend({}, doc) # Shallow copy.
      doc._id = Random.id()

    APP.justdo_analytics.logMongoRawConnectionOp(collection._name, "insert", doc)
    collection.rawCollection().insert doc, (err, result) ->
      fiber.run({err, result})

      return
    
    return Fiber.yield()

  pseudoBlockingRawCollectionUpdateInsideFiber: (collection, selector, modifier, options) ->
    fiber = @getCurrentFiber()

    if not (fiber = Fiber.current)?
      throw throw new Error("no-fiber")

    APP.justdo_analytics.logMongoRawConnectionOp(collection._name, "update", selector, modifier, options)
    collection.rawCollection().update selector, modifier, options, (err, result) ->
      fiber.run({err, result})

      return
    
    return Fiber.yield()

  pseudoBlockingRawCollectionCountInsideFiber: (collection, query, count_options) ->
    fiber = @getCurrentFiber()

    if not (fiber = Fiber.current)?
      throw throw new Error("no-fiber")

    count_promise = collection.rawCollection().count(query, count_options)
      .then((count) =>
        fiber.run({count: count})
      
        return
      )
      .catch((err) =>
        fiber.run({err})
      
        return
      )
    return Fiber.yield()