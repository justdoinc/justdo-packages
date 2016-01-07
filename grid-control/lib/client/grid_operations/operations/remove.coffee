callCb = PACK.helpers.callCb

_.extend PACK.GridOperations,
  removeActivePath:
    op: (cb) ->
      @_performLockingOperation (releaseOpsLock, timedout) =>
        active_path = @getActiveCellPath()
        next_path = @_grid_data.getNextPath(active_path)
        prev_path = @_grid_data.getPreviousPath(active_path)

        @_grid_data.removeParent active_path, (err) =>
          if err?
            @logger.error "removeActivePath failed: #{err}"

            callCb cb, err

            releaseOpsLock()

            return

          # Make sure item removed from DOM
          @_grid_data._flush()

          callCb cb, err

          if next_path?
            @activatePath(next_path)
          else if prev_path?
            @activatePath(prev_path)

          # Release lock only after activation of next path to
          # avoid any chance of refering to removed path in
          # following operations
          releaseOpsLock()

    prereq: -> @_opreqActivePathIsLeaf(@_opreqUnlocked(@_opreqGridReady()))