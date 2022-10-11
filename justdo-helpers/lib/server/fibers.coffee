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
    return undefined

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

  pseudoBlockingRawCollectionUpdateInsideFiber: (collection, selector, modifier, options) ->
    fiber = @getCurrentFiber()

    if not (fiber = Fiber.current)?
      throw throw new Error("no-fiber")

    APP.justdo_analytics.logMongoRawConnectionOp(collection._name, "update", selector, modifier, options)
    collection.rawCollection().update selector, modifier, options, (err, result) ->
      fiber.run({err, result})

      return
    
    return Fiber.yield()