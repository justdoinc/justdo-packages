callCb = PACK.helpers.callCb

getPathLevel = GridData.helpers.getPathLevel # shortcut

_.extend PACK.GridOperations,
  moveActivePathDown:
    op: (cb) ->
      @_performLockingOperation (releaseOpsLock, timedout) =>
        is_multi_select = @isMultiSelectMode()

        if is_multi_select
          selected_items = @getFilterPassingMultiSelectedPathsArray()
          active_path = selected_items[selected_items.length - 1] # if multi-select consider active_path as the last item of the consecutive selection
        else
          active_path = @getCurrentPath()

        next_path = @_grid_data.filterAwareGetNextLteLevelPath(active_path)

        relation_to_next_path = 1
        if getPathLevel(active_path) > getPathLevel(next_path)
          relation_to_next_path = -1
        else if @_grid_data.filterAwareGetPathExpandState(next_path) == 1
          # If next item is expanded: place before first child
          relation_to_next_path = -1
          next_path = @_grid_data.filterAwareGetNextPath(next_path)

        if is_multi_select
          paths_to_move = @getFilterPassingMultiSelectedPathsArray()
        else
          paths_to_move = [active_path]

        @_grid_data._lock()
        @movePath paths_to_move, [next_path, relation_to_next_path], (err, new_paths) =>
          @_grid_data._release()
          if err?
            @logger.error "moveActivePath failed: #{err}"

            callCb cb, err

            releaseOpsLock()

            return

          if @_grid_data.filterAwareGetPathExpandState(active_path) == 1
            @_grid_data.collapsePath active_path

          # Flush to make sure DOM is up-to-date before the call to cb
          @_grid_data._flushAndRebuild()

          if is_multi_select
            @setMultiSelectedPathsFromArray new_paths
          else
            @activatePath new_paths[0]

          callCb cb, err

          # Release lock only after activation of next path to
          # avoid any chance of refering to removed path in
          # following operations
          releaseOpsLock()

    prereq: ->
      @_opreqActivePathLevelPermitted(
        @_opreqItemInLteLevelExistFollowingActiveInPermittedLevel(
          @_opreqSingleSelectModeOrConsecutiveMultiSelect(
            @_opreqActivePathIsCollectionItem(
              @_opreqUnlocked(
                  @_opreqGridReady()
              )
            )
          )
        )
      )

  moveActivePathUp:
    op: (cb) ->
      @_performLockingOperation (releaseOpsLock, timedout) =>
        is_multi_select = @isMultiSelectMode()

        if is_multi_select
          selected_items = @getFilterPassingMultiSelectedPathsArray()
          active_path = selected_items[0] # if multi-select consider active_path as the first item of the consecutive selection
        else
          active_path = @getCurrentPath()

        prev_path = @_grid_data.filterAwareGetPreviousPath(active_path)

        relation_to_prev_path = -1
        if getPathLevel(active_path) < getPathLevel(prev_path)
          relation_to_prev_path = 1

        if is_multi_select
          paths_to_move = @getFilterPassingMultiSelectedPathsArray()
        else
          paths_to_move = [active_path]

        @_grid_data._lock()
        @movePath paths_to_move, [prev_path, relation_to_prev_path], (err, new_paths) =>
          @_grid_data._release()
          if err?
            @logger.error "moveActivePath failed: #{err}"

            callCb cb, err

            releaseOpsLock()

            return

          if @_grid_data.filterAwareGetPathExpandState(active_path) == 1
            @_grid_data.collapsePath active_path

          # Flush to make sure DOM is up-to-date before the call to cb
          @_grid_data._flushAndRebuild()

          if is_multi_select
            @setMultiSelectedPathsFromArray new_paths
          else
            @activatePath new_paths[0]

          callCb cb, err

          # Release lock only after activation of prev path to
          # avoid any chance of refering to removed path in
          # following operations
          releaseOpsLock()

    prereq: ->
      @_opreqActivePathLevelPermitted(
        @_opreqActivePathPrevItemLevelPermitted(
          @_opreqActiveItemIsntSectionFirstItem(
            @_opreqSingleSelectModeOrConsecutiveMultiSelect(
              @_opreqActivePathIsCollectionItem(
                @_opreqUnlocked(
                    @_opreqGridReady()
                )
              )
            )
          )
        )
      )

  moveActivePathLeft:
    op: (cb) ->
      @_performLockingOperation (releaseOpsLock, timedout) =>
        is_multi_select = @isMultiSelectMode()

        if is_multi_select
          selected_items = @getFilterPassingMultiSelectedPathsArray()
          active_path = selected_items[0] # if multi-select consider active_path as the first item of the consecutive selection
        else
          active_path = @getCurrentPath()

        parent_path = GridData.helpers.getParentPath(active_path)

        if is_multi_select
          paths_to_move = @getFilterPassingMultiSelectedPathsArray()
        else
          paths_to_move = [active_path]

        @_grid_data._lock()
        @movePath paths_to_move, [parent_path, 1], (err, new_paths) =>
          @_grid_data._release()
          if err?
            @logger.error "moveActivePath failed: #{err}"

            callCb cb, err

            releaseOpsLock()

            return

          if @_grid_data.filterAwareGetPathExpandState(active_path) == 1
            @_grid_data.collapsePath active_path

          # Flush to make sure DOM is up-to-date before the call to cb
          @_grid_data._flushAndRebuild()

          if is_multi_select
            @setMultiSelectedPathsFromArray new_paths
          else
            @activatePath new_paths[0]

          callCb cb, err

          # Release lock only after activation of prev path to
          # avoid any chance of refering to removed path in
          # following operations
          releaseOpsLock()

    prereq: ->
      @_opreqActivePathParentLevelPermitted(
        @_opreqActiveItemIsntSectionTopLevel(
          @_opreqSingleSelectModeOrConsecutiveMultiSelect(
            @_opreqActivePathIsCollectionItem(
              @_opreqUnlocked(
                  @_opreqGridReady()
              )
            )
          )
        )
      )

  moveActivePathRight:
    op: (cb) ->
      @_performLockingOperation (releaseOpsLock, timedout) =>
        is_multi_select = @isMultiSelectMode()

        if is_multi_select
          selected_items = @getFilterPassingMultiSelectedPathsArray()
          active_path = selected_items[0] # if multi-select consider active_path as the first item of the consecutive selection
        else
          active_path = @getCurrentPath()

        prev_path = @_grid_data.filterAwareGetPreviousPath(active_path)

        active_path_level = getPathLevel(active_path)
        prev_path_level = getPathLevel(prev_path)

        if active_path_level == prev_path_level
          # Prev item is either collapsed or child-less - put as first
          relation = 0
          target_path = prev_path
        else
          # Prev item is either expanded - put as last
          relation = 2
          prev_path_array = GridData.helpers.getPathArray(prev_path)

          target_path = "/"
          for i in [0..active_path_level]
            target_path += prev_path_array[i] + "/"

        if is_multi_select
          paths_to_move = @getFilterPassingMultiSelectedPathsArray()
        else
          paths_to_move = [active_path]

        @_grid_data._lock()
        @movePath paths_to_move, [target_path, relation], (err, new_paths) =>
          @_grid_data._release()
          if err?
            @logger.error "moveActivePath failed: #{err}"

            callCb cb, err

            releaseOpsLock()

            return

          if @_grid_data.filterAwareGetPathExpandState(active_path) == 1
            @_grid_data.collapsePath active_path

          @_grid_data.expandPath target_path

          # Flush to make sure DOM is up-to-date before the call to cb
          @_grid_data._flushAndRebuild()

          if is_multi_select
            @setMultiSelectedPathsFromArray new_paths
          else
            @activatePath new_paths[0]

          callCb cb, err

          # Release lock only after activation of prev path to
          # avoid any chance of refering to removed path in
          # following operations
          releaseOpsLock()

    prereq: ->
      @_opreqActivePathLevelPermitted(
        @_opreqActivePathPrevItemInGteLevel(
          @_opreqSingleSelectModeOrConsecutiveMultiSelect(
            @_opreqActivePathIsCollectionItem(
              @_opreqUnlocked(
                  @_opreqGridReady()
              )
            )
          )
        )
      )
