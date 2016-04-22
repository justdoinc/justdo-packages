callCb = PACK.helpers.callCb

_.extend PACK.GridOperations,
  sortActivePathByPriorityDesc:
    op: (cb) ->
      @_performLockingOperation (releaseOpsLock, timedout) =>
        active_path = @getActiveCellPath()

        @_grid_data.sortChildren active_path, "priority", -1, (err) =>
          if err?
            @logger.error "sortActivePathByPriorityDesc failed: #{err}"

            callCb cb, err

            releaseOpsLock()

            return

          releaseOpsLock()

    prereq: -> @_opreqActivePathChildrenLevelPermitted(@_opreqActivePathHasChildren(@_opreqActivePathIsCollectionItem(@_opreqUnlocked(@_opreqGridReady()))))