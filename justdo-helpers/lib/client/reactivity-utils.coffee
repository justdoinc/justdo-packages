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

    reactive_resource_tracker = Tracker.nonreactive ->
      initial_run = true
      tracker = Tracker.autorun ->
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