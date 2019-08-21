_.extend JustdoHelpers,
  callCb: (cb, ...args) ->
    if cb? and _.isFunction(cb)
      return cb.apply(@, args)

    return undefined