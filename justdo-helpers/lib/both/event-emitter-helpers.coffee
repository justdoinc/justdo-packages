_.extend JustdoHelpers,
  # events_array [event_item, event_item, ...]
  # event_item structure: ["hook-type", "event-name", cb]
  # Example item: ["once", "stop", ->]

  loadEventEmitterHelperMethods: JustdoCoreHelpers.loadEventEmitterHelperMethods

  loadEventsArray: JustdoCoreHelpers.loadEventsArray

  unloadEventsArray: JustdoCoreHelpers.unloadEventsArray
