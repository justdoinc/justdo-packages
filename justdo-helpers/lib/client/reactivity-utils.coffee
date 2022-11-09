_.extend JustdoHelpers,
  delayedReactiveResourceOutput: (reactiveResource, delay_ms) ->
    # When reactiveResource is invalidated, we will trigger invalidation
    # after delay_ms miliseconds instead o immediately.

    if not Tracker.currentComputation?
      # Not running inside reactive comp, simply return the output
      return reactiveResource()

    dep = new Tracker.Dependency()

    dep.depend()

    value = undefined

    reactive_resource_tracker = null
    Tracker.nonreactive ->
      initial_run = true
      reactive_resource_tracker = Tracker.autorun ->
        value = reactiveResource()

        if not initial_run
          invalidation_timeout = setTimeout ->
            dep.changed()
          , delay_ms

        initial_run = false

        return

    Tracker.onInvalidate ->
      reactive_resource_tracker.stop()

      return

    return value

  awaitValueFromReactiveResource: (options) ->
    # Calls options.cb() a single time once options.reactiveResource() returns a value that when
    # passed as the first argument to options.evaluator(val), true is returned.
    #
    # Notes:
    #
    # 1. This is a NON REACTIVE method
    # 2. options.cb can be called either in the current tick or in a future tick!

    Tracker.nonreactive =>
      comp = Tracker.autorun (c) =>
        returned_val = options.reactiveResource()
        if Tracker.nonreactive -> options.evaluator(returned_val) is true
          Tracker.nonreactive -> JustdoHelpers.callCb(options.cb)

          c.stop()

          return

        return

      if options.timeout
        Meteor.setTimeout ->
          comp.stop()
        , options.timeout

    return