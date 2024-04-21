default_options =
  container: null
  items_subscription: null
  shared_grid_control_options: null

  # If set to true, one GridDataCore object will
  # be created and managed by the mux for all its
  # GridControls' GridData.
  # (Optimizes memory and CPU usage).
  use_shared_grid_data_core: false

  # Relevant only if use_shared_grid_data_core is true
  # The options obj with which the shared GridDataCore
  # will initiate
  shared_grid_data_core_options: {}

  # If set to true, one GridControlCustomFieldsManager object will
  # be created and managed by the mux for all its GridControls'.
  use_shared_grid_control_custom_fields_manager: false

  # Relevant only if use_shared_grid_control_custom_fields_manager is true
  # The options obj with which the shared GridControlCustomFieldsManager
  # will be initiated with
  shared_grid_control_custom_fields_manager_options: {}

  # Same as use_shared_grid_control_custom_fields_manager but for the removed
  # custom fields
  use_shared_grid_control_removed_custom_fields_manager: false

  # Same as shared_grid_control_removed_custom_fields_manager_options but for the removed
  # custom fields
  shared_grid_control_removed_custom_fields_manager_options: {}

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
    # on the client, call @_immediateInit() in an isolated
    # computation to avoid our init procedures from affecting
    # the encapsulating computation (if any)
    Tracker.nonreactive =>
      @_immediateInit()

    # React to invalidations
    if Tracker.currentComputation?
      Tracker.onInvalidate =>
        @logger.debug "Enclosing computation invalidated, destroying"
        @destroy() # defined in client/api.coffee
  else
    @_immediateInit()

  Meteor.defer =>
    @_deferredInit()

  @logger.debug "Init done"

  return @

Util.inherits GridControlMux, EventEmitter

_.extend GridControlMux.prototype,
  _error: JustdoHelpers.constructor_error
