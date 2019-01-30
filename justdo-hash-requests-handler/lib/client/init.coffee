default_options = {}

options_schema =
  both:
    prefix:
      type: "string"
      optional: false
      bind_to_instance: true

HashRequestsHandler = (options) ->
  # skeleton-version: v0.0.4

  EventEmitter.call this

  @destroyed = false

  @logger = Logger.get("hash-requests-handler")

  @logger.debug "Init begin"

  @options = _.extend {}, default_options, options
  if not _.isEmpty(options_schema)
    # If options_schema is set, use it to apply strict structure on
    # @options.
    #
    # Clean and validate @options according to options_schema.
    # invalid-options error will be thrown for invalid options.
    # Takes care of binding options with bind_to_instance to
    # the instance.
    @options =
      JustdoHelpers.loadOptionsWithSchema(
        options_schema, @options, {
          self: @
          additional_schema: # Adds the `events' option to the permitted fields
            events:
              type: Object
              blackbox: true
              optional: true
        }
      )

  JustdoHelpers.loadEventEmitterHelperMethods(@)
  @loadEventsFromOptions() # loads @options.events, if exists

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

  Meteor.defer =>
    @_deferredInit()

  @logger.debug "Init done"

  return @

Util.inherits HashRequestsHandler, EventEmitter

_.extend HashRequestsHandler.prototype,
  _error: JustdoHelpers.constructor_error

  _immediateInit: ->
    @running = false

    @request_handlers = {}

    # Note that request args must be prefixed with & or ?
    @request_args_regexp = RegExp("[&?]#{@options.prefix}-([^&=]+)=([^&=]+)", "g")

    return

  _deferredInit: ->
    return
