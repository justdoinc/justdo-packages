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
  EventEmitter.call this

  @logger = Logger.get("grid-control-mux")

  @logger.debug "Initializing"

  @options = _.extend {}, default_options, options

  @_immediateInit()

  Meteor.defer =>
    @_deferredInit()

  @logger.debug "Init complete"

  return @

Util.inherits GridControlMux, EventEmitter

_.extend GridControlMux.prototype,
  _error: JustdoHelpers.constructor_error