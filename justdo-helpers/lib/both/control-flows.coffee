timeouts = {}

_.extend JustdoHelpers,
  delayedCallOfLastRequest: (options) ->
    # Call func after timeout, unless another func was given
    # to it with same manager_id before timeout.
    #
    # cb will be called with func output as first param

    {manager_id, timeout, func, cb} = options

    if manager_id of timeouts
      clearTimeout timeouts[manager_id]

    timeouts[manager_id] = setTimeout ->
      JustdoHelpers.callCb(cb, func())

      delete timeouts[manager_id]
    , timeout

    return
