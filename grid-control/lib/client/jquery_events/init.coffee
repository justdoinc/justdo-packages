GridControl.jquery_builtin_events = []

_.extend GridControl.prototype,
  _jquery_events_destructors: null
  _custom_jquery_events: null
  _jquery_events_init_completed: false

  _init_jquery_events: ->
    @_jquery_events_destructors = []

    events_to_init = GridControl.jquery_builtin_events

    if @_custom_jquery_events?
      events_to_init = events_to_init.concat(@_custom_jquery_events)

    for event_definition in events_to_init
      @_loadjQueryEvent(event_definition)

    @_jquery_events_init_completed = true

    return

  installCustomJqueryEvent: (event_definition) ->
    # Adds a jquery based event handler that will be binded
    # when the main @init method will call @_init_jquery_events
    # or, if @_init_jquery_events already called, immediately.

    # The events are binded to / listen on the grid-control container
    # element.

    # We take care of unbinding the event upon the grid-control
    # destroy.

    #
    # event_definition structure
    #
    # {
    #   args: [] # an array of the arguments that will be used to bind the event
    #            # the args are passed to the jquery's '$(grid-control-container).on'
    #            # command
    #           
    #   handler: # a function, the event handler
    # }

    if not @_jquery_events_init_completed
      # didn't init jquery events handler yet, add @_custom_jquery_events
      # which includes all the defs we'll bind when @_init_jquery_events
      # will be called.
      if not (custom_jquery_events = @_custom_jquery_events)?
        custom_jquery_events = @_custom_jquery_events = []

      custom_jquery_events.push event_definition
    else
      @_loadjQueryEvent(event_definition)

    return

  _loadjQueryEvent: (event_definition) ->
    event_handler = (e) =>
      event_definition.handler.call(@, e)

    args = event_definition.args.concat [event_handler]

    container = $(@container)
    container.on.apply(container, args)

    @_jquery_events_destructors.push args

    return

  _destroy_jquery_events: ->
    if @_jquery_events_destructors
      # If initiated

      container = $(@container)
      for event_args in @_jquery_events_destructors
        container.off.apply(container, event_args)

    return