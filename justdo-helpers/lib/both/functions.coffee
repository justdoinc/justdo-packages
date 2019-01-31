_.extend JustdoHelpers,
  callCb: ->
    # callCb(cb, args*)
    # calls cb if cb is function with provided args, saves the need
    # to check existence
    cb = arguments[0]
    args = _.toArray(arguments).slice(1)

    if cb? and _.isFunction(cb)
      cb.apply(@, args)