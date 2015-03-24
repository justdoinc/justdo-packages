PACK.jquery_events = []

_.extend GridControl.prototype,
  _jquery_events_destructors: null
  _init_jquery_events: _.once ->
    @_jquery_events_destructors = []

    for event in PACK.jquery_events
      do (event) =>
        event_handler = (e) =>
          event.handler.call(@, e)

        args = event.args.concat [event_handler]

        container = $(@container)
        container.on.apply(container, args)

        @_jquery_events_destructors.push args

  _destroy_jquery_events: _.once ->
    for event in @_jquery_events_destructors
      do (event) =>
        container = $(@container)
        container.off.apply(container, event)
