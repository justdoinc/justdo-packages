# FlushManager gather requests to emit an event named
# `flush` and makes sure that multiple requests that
# were called in a very short time one after the other
# will trigger only a single `flush` event.
#
# The main purpose is to perform expensive updates
# required by multiple events (those calling the
# setNeedFlush()), in bulk.
#
# In addition to the flush event, FlushManager also
# introduces a reactive resource invalidateOnFlush()
# that will invalidate every time the `flush` event
# is called (for case reaction to the flush event
# should be done on Meteor's flush phase - i.e.
# when Meteor is idle).
#
# Basic methods:
# @setNeedFlush() - request emittion of the 'flush' event
# @lock() - Don't perform any flush, even if required
# @release(immediate=true) - Release the lock, if immediate is true,
#                            if flush requested during lock, flush
#                            will emit immediately, otherwise @setNeedFlush()
#                            will call.

default_options =
  min_flush_delay: 80 # The minimal time in ms, since last call for
                      # @setNeedFlush to the 'flush' event emittion
                      # E.g. if set to 100, if setNeedFlush will be
                      # called once, and after 99ms another time and
                      # no additional setNeedFlush calls will receive
                      # the flush event will emit atleast: 199ms after
                      # first setNeedFlush.

FlushManager = (options) ->
  # skeleton-version: v0.0.2

  EventEmitter.call this

  @destroyed = false

  @_flush_manager_id = Random.id()
  @_same_tick_cache_key = "flush-manager::#{@_flush_manager_id}"

  @logger = Logger.get("flush-manager")

  @logger.debug "Init begin"

  @options = _.extend {}, default_options, options

  JustdoHelpers.loadEventEmitterHelperMethods(@)
  @loadEventsFromOptions() # loads @options.events, if exists

  Tracker.nonreactive =>
    # We don't want FM's internal computation to affect
    # any enclosing computations
    @_immediateInit()

  Meteor.defer =>
    @_deferredInit()

  @logger.debug "Init done"

  return @

Util.inherits FlushManager, EventEmitter

_.extend FlushManager.prototype,
  # In an effort to encourage standardizing errors types we will issue a warning 
  # if an error of type other than the following will be used
  # The value is the default message
  _errors_types: {}

  _error: JustdoHelpers.constructor_error

  _immediateInit: ->
    @flush_dependency = new Tracker.Dependency()

    @_set_need_flush_timeout = null
    @_flush_lock = false
    @_flush_blocked_by_lock = false

    return

  _deferredInit: ->
    return

  _isFlushRequestedInThisTick: ->
    return JustdoHelpers.sameTickCacheGet(@_same_tick_cache_key)?

  _setFlushRequestedInThisTick: ->
    return JustdoHelpers.sameTickCacheSet(@_same_tick_cache_key, true)

  _unsetFlushRequestedInThisTick: ->
    return JustdoHelpers.sameTickCacheSet(@_same_tick_cache_key, null)

  setNeedFlush: ->
    if @destroyed
      return

    if @_flush_lock
      @_flush_blocked_by_lock = true

      return

    # If already requested in this tick, nothing to do ...
    if @_isFlushRequestedInThisTick()
      return

    @_setFlushRequestedInThisTick()

    if @_set_need_flush_timeout?
      clearTimeout @_set_need_flush_timeout

    @_set_need_flush_timeout = setTimeout =>
      @_set_need_flush_timeout = null

      @_flush()
    , @options.min_flush_delay

    return

  lock: ->
    # Lock
    @_flush_lock = true

    # Remove flush that's about to happen
    if @_set_need_flush_timeout?
      clearTimeout @_set_need_flush_timeout
      @_set_need_flush_timeout = null

      # Mark that a flush is needed upon release
      @_flush_blocked_by_lock = true

    return

  release: (immediate=true) ->
    @_flush_lock = false

    # If flush was blocked, flush
    if @_flush_blocked_by_lock
      @_flush_blocked_by_lock = false

      if immediate
        @_flush()
      else
        @setNeedFlush()

    return

  invalidateOnFlush: ->
    # invalidates every time we emit the flush event.
    @flush_dependency.depend()

    return

  _flush: ->
    if @destroyed
      return
    
    @_unsetFlushRequestedInThisTick()

    @emit "flush"
    @flush_dependency.changed()

    return

  destroy: ->
    if @destroyed
      @logger.debug "Destroyed already"

      return

    @destroyed = true

    @logger.debug "Destroyed"

    return

JustdoHelpers.FlushManager = FlushManager