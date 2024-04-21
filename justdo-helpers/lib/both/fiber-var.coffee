if Meteor.isServer
  Fiber = Npm.require "fibers"
else
  # In the client we don't have fibers, we use a simple var to store the
  # vars

  fake_fiber_cache = {}

_.extend JustdoHelpers,
  getCurrentFiberObject: ->
    if Meteor.isServer
      process.google = Fiber
      return Fiber.current
    else
      return fake_fiber_cache

  isFiberVarExists: (var_name) ->
    return var_name of JustdoHelpers.getCurrentFiberObject()

  getFiberVar: (var_name) ->
    return JustdoHelpers.getCurrentFiberObject()[var_name]

  setFiberVar: (var_name, var_value) ->
    return JustdoHelpers.getCurrentFiberObject()[var_name] = var_value

  deleteFiberVar: (var_name) ->
    delete JustdoHelpers.getCurrentFiberObject()[var_name]

    return

  getFiberId: ->
    id_key = "___id"

    if not @getCurrentFiber()?
      return undefined

    if not @isFiberVarExists(id_key)
      @setFiberVar(id_key, Random.id())

    return @getFiberVar(id_key)

  runCbInFiberScope: (var_name, var_value, cb) ->
    # Set var_name to var_value for the invocation of cb, and sets var_name to its
    # original value afterwards.
    #
    # Returns the cb returned value

    if (was_set = JustdoHelpers.isFiberVarExists(var_name))
      original_value = JustdoHelpers.getFiberVar(var_name)

    revertValue = ->
      if not was_set
        JustdoHelpers.deleteFiberVar(var_name)
      else
        JustdoHelpers.setFiberVar(var_name, original_value)
      
      return

    JustdoHelpers.setFiberVar(var_name, var_value)

    try
      cb_ret = JustdoHelpers.callCb cb
    catch e
      revertValue()

      throw e

    revertValue()

    return cb_ret
