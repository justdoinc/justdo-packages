lock_timeout = 5000

_.extend GridControl.prototype,
  # Note, operations locks are defined here and not in grid_data
  # level since the timing of the lock release depends on the dom
  # updates (flush) required following operations.
  # See as an example the point in which we release the lock in 
  # the addItem operation.
  # Also, we see grid_data as a more low level operations api where
  # we allow multy operations to occur in a non-sequential manner.
  # Useful for compound operations (that use more than one grid-data
  # operation).

  operationsLocked: -> @_operations_lock.get()
  operationsLockExpired: -> @_operations_lock_timedout.get()

  _performLockingOperation: (op) ->
    # Calls op with two args: releaseOpsLock, timedout
    # op is expected to call releaseOpsLock as soon as lock isn't
    # necessary.
    # timedout is a method that returned true if lock was released
    # due to timeout. It should be used as a mean for op to behave
    # differently if it returned after other operations allowed to
    # perform.
    is_locked = Tracker.nonreactive => @_operations_lock.get()

    if is_locked
      throw @_error "active-operations-lock"

    @_operations_lock_timedout.set(false)

    releaseOpsLock = _.once =>
      # once is used to allow each operation to releaseOpsLock only once
      # (to avoid any risk of interference with following ops)
      @_operations_lock.set false

      Meteor.clearTimeout timeout_id

      if timedout
        @_operations_lock_timedout.set(true)

    _timedout = false
    timeout_id = Meteor.setTimeout =>
      @logger.warn "Operations lock released due to timeout"

      releaseOpsLock()

      _timedout = true
    , lock_timeout

    timedout = -> _timedout

    @_operations_lock.set true

    op releaseOpsLock, timedout