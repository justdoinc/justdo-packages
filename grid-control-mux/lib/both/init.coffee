default_options =
  container: null
  items_subscription: null
  use_shared_grid_data_core: false # If set to true, one GridDataCore object will
                                   # be created and managed by the mux for all its
                                   # GridControls' GridData.
                                   # (Optimizes memory and CPU usage).
  shared_grid_data_core_options: {} # Relevant only if use_shared_grid_data_core is true
                                    # The options obj with which the shared GridDataCore
                                    # will initiate


GridControlMux = (options) ->
  # skeleton-version: v0.0.2

  # only both/errors-types.coffee upgraded to skeleton-version: v0.0.8

  EventEmitter.call this

  @destroyed = false

  @logger = Logger.get("grid-control-mux")

  @logger.debug "Initializing"

  @options = _.extend {}, default_options, options

  JustdoHelpers.loadEventEmitterHelperMethods(@)
  @loadEventsFromOptions() # loads @options.events, if exists

  if Meteor.isClient
    # React to invalidations
    if Tracker.currentComputation?
      Tracker.onInvalidate =>
        @logger.debug "Enclosing computation invalidated, destroying"
        @destroy() # defined in client/api.coffee

    # on the client, call @_immediateInit() in an isolated
    # computation to avoid our init procedures from affecting
    # the encapsulating computation (if any)
    Tracker.nonreactive =>
      @_immediateInit()
  else
    @_immediateInit()

  Meteor.defer =>
    @_deferredInit()

  @logger.debug "Init done"

  return @

Util.inherits GridControlMux, EventEmitter

_.extend GridControlMux.prototype,
  _error: JustdoHelpers.constructor_error
