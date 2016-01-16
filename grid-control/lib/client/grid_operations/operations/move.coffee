callCb = PACK.helpers.callCb

_.extend PACK.GridOperations,
  moveActivePathDown:
    op: (cb) ->
      @_performLockingOperation (releaseOpsLock, timedout) =>
        active_path = @getActiveCellPath()

        next_path = @_grid_data.getNextLteLevelPath(active_path)

        relation_to_next_path = 1
        if @_grid_data.getPathLevel(active_path) > @_grid_data.getPathLevel(next_path)
          relation_to_next_path = -1
        else if @_grid_data.getPathIsExpand(next_path)
          # If next item is expanded: place before first child
          relation_to_next_path = -1
          next_path = @_grid_data.getNextPath(next_path)

        @_grid_data._lock_flush()
        @_grid_data.movePath active_path, [next_path, relation_to_next_path], (err, new_path) =>
          @_grid_data._release_flush()
          if err?
            @logger.error "moveActivePath failed: #{err}"

            callCb cb, err

            releaseOpsLock()

            return

          if @_grid_data.getPathIsExpand active_path
            @_grid_data.collapsePath active_path

          # Flush to make sure DOM is up-to-date before the call to cb
          @_grid_data._flush()

          @activatePath new_path

          callCb cb, err

          # Release lock only after activation of next path to
          # avoid any chance of refering to removed path in
          # following operations
          releaseOpsLock()

    prereq: -> @_opreqItemInLteLevelExistFollwingActive(@_opreqUnlocked(@_opreqGridReady()))

  moveActivePathUp:
    op: (cb) ->
      @_performLockingOperation (releaseOpsLock, timedout) =>
        active_path = @getActiveCellPath()

        prev_path = @_grid_data.getPreviousPath(active_path)

        relation_to_prev_path = -1
        if @_grid_data.getPathLevel(active_path) < @_grid_data.getPathLevel(prev_path)
          relation_to_prev_path = 1

        @_grid_data._lock_flush()
        @_grid_data.movePath active_path, [prev_path, relation_to_prev_path], (err, new_path) =>
          @_grid_data._release_flush()
          if err?
            @logger.error "moveActivePath failed: #{err}"

            callCb cb, err

            releaseOpsLock()

            return

          if @_grid_data.getPathIsExpand active_path
            @_grid_data.collapsePath active_path

          # Flush to make sure DOM is up-to-date before the call to cb
          @_grid_data._flush()

          @activatePath new_path

          callCb cb, err

          # Release lock only after activation of prev path to
          # avoid any chance of refering to removed path in
          # following operations
          releaseOpsLock()

    prereq: -> @_opreqActiveItemIsntFirst(@_opreqUnlocked(@_opreqGridReady()))