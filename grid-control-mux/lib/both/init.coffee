default_options =
  container: null
  items_subscription: null

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