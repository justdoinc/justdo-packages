helpers = share.helpers

default_options =
  sections: 
    [
      {
        id: "main"

        section_manager: "DataTreeSection"
      }
    ]

GridData = (collection, options) ->
  EventEmitter.call this

  @logger = Logger.get("grid-data")

  @collection = collection
  @options = _.extend {}, default_options, options

  if not (schema = @collection.simpleSchema())?
    @logger.debug "GridData called for a collection with no simpleSchema definition"
    return

  # XXX need to find a way to bring normalized schema from GridControl
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
      return
    @_destroyed = true

    if @_items_tracker?
      @_items_tracker.stop()
      @_items_tracker = null # As of Meteor 1.0.4 observers handles don't have
                             # computation-like stopped attribute. Threfore we
                             # set _items_tracker back to null, so we can test
                             # that it's stopped.

    if @_flush_orchestrator?
      @_flush_orchestrator.stop()

    @_destroy_filter_manager()

    @_destroy_foreign_keys_trackers()

    @emit "destroyed"