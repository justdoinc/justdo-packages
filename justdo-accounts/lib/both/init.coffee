default_options =
  new_accounts_custom_fields: {}

JustdoAccounts = (options) ->
  # skeleton-version: v0.0.2

  EventEmitter.call this

  @destroyed = false

  @logger = Logger.get("justdo-accounts")

  @logger.debug "Init begin"

  @options = _.extend {}, default_options, options

  JustdoHelpers.loadEventEmitterHelperMethods(@)
  @loadEventsFromOptions() # loads @options.events, if exists

  @_attachSchema()

  if Meteor.isClient
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

Util.inherits JustdoAccounts, EventEmitter

_.extend JustdoAccounts.prototype,
  _error: JustdoHelpers.constructor_error
