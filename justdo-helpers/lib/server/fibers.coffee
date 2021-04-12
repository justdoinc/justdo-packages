Fiber = Npm.require "fibers"

_.extend JustdoHelpers,
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