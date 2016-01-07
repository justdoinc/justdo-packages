PACK.helpers =
  callCb: ->
    cb = arguments[0]
    args = _.toArray(arguments).slice(1)

    if cb? and _.isFunction(cb)
      cb.apply(@, args)