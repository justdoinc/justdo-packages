_.extend JustdoHelpers,
  # events_array [event_item, event_item, ...]
  # event_item structure: ["hook-type", "event-name", cb]
  # Example item: ["once", "stop", ->]

  loadEventEmitterHelperMethods: (obj) ->
    obj.loadEventsFromOptions = ->
      # Looks for obj's @options.events, and loads it
      # using loadEventsArray if exists
      if (events = @options?.events)?
        @loadEventsArray(events)

      return

    obj.loadEventsArray = (events_array) ->
      JustdoHelpers.loadEventsArray(@, events_array)

      return

    obj.unloadEventsArray = (events_array) ->
      JustdoHelpers.unloadEventsArray(@, events_array)

      return

  loadEventsArray: (obj, events_array) ->
    # Assumes obj inherits from EventEmitter

    for item in events_array
      [hook_type, event_name, event_cb] = item

      obj[hook_type](event_name, event_cb)

    return

  unloadEventsArray: (obj, events_array) ->
    for item in events_array
      [hook_type, event_name, event_cb] = item

      obj.removeListener(event_name, event_cb)

    return