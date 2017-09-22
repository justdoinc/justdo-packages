helpers = share.helpers

default_options =
  grid_control: null # A reference to the grid_control initiating this GridData

  grid_data_core: null # a GridDataCore object can be provided to us
                       # useful if multiple grids shares the same core
                       # data structures
                       # If null, grid-data will inits its own GridDataCore
                       # object

  grid_data_core_options: {} # Relevant only if grid_data_core is null.
                             # In such case, we will init GridDataCore
                             # with these options.

  sections:
    [
      {
        id: "main"

        section_manager: "DataTreeSection"

        options:
          permitted_depth: 0
      }
    ]

GridData = (collection, options) ->
  EventEmitter.call this

  @logger = Logger.get("grid-data")

  @collection = collection
  @options = _.extend {}, default_options, options

  # Load/init GridDataCore, only if init triggered
  # by this GridData instance, it'll be destroyed
  # on @destroy
  @_grid_data_core_initiated_by_us = false
  if not (@_grid_data_core = @options.grid_data_core)?
    @_grid_data_core_initiated_by_us = true

    gdc_options = _.extend {}, @options.grid_data_core_options
    if not gdc_options.collection?
      gdc_options.collection = @collection

    @_grid_data_core =
      new GridDataCore(gdc_options)

  if not (schema = @collection.simpleSchema())?
    @logger.debug "GridData called for a collection with no simpleSchema definition"
    return

  @grid_control = @options.grid_control

  # XXX need to find a way to bring normalized schema from GridControl
  # XXX2 Now that grid_control is passed as an option, might be the way to do so
  @schema = schema._schema

  @_initialized = false
  @_destroyed = false

  @_initMetadata()

  #
  # Call data structures managers init funcs
  #
  # Call filters's init before the core data structures' init, so if a filter
  # will be set before the `_perform_deferred_procedures` event is emitted, it
  # will be handeled by the filters deferred procedures before the core data
  # structure deferred procedures. This way the filter will be ready on init.
  @_initFilters()

  @_initCoreStructures()

  @_initGridSections() # defined in grid-sections.coffee

  @_initItemsTypes() # defined in items-types.coffee

  Meteor.defer =>
    # give a chance for event binding and other procedures by caller
    # (such as setting filters, etc.) before actual init procedures
    # performed once "_perform_deferred_procedures" event is emitted.
    @_init()

  if Tracker.currentComputation?
    Tracker.onInvalidate =>
      @destroy()

  return @

GridData.helpers = helpers # Expose helpers to other packages throw GridData

Util.inherits GridData, EventEmitter

_.extend GridData.prototype,
  _error: JustdoHelpers.constructor_error

  _init: ->
    if @_initialized or @_destroyed
      return

    @emit "_perform_deferred_procedures"

    @_initialized = true

    @emit "init"

  destroy: ->
    if @_destroyed
      @logger.debug "Destroyed already"

      return

    @_destroyed = true

    @_destroySectionManagers()

    if @_flush_orchestrator?
      @_flush_orchestrator.stop()

    if @_rebuild_orchestrator?
      @_rebuild_orchestrator.stop()

    @_destroy_filter_manager()

    if @_grid_data_core_initiated_by_us
      @_grid_data_core.destroy()

    @emit "destroyed"
