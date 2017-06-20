callCb = PACK.helpers.callCb

_.extend PACK.GridOperations,
  removeActivePath:
    op: (cb) ->
      @_performLockingOperation (releaseOpsLock, timedout) =>
        active_path = @getCurrentPath()
        active_item_row = @getCurrentRow()

        active_item_section = @_grid_data.getItemSection(active_item_row)

        # find next/prev paths
        next_path = prev_path = null
        next_item = @_grid_data.filterAwareGetNextItem(active_item_row)
        if next_item?
          next_path = @_grid_data.getItemPath(next_item)
        else # If we couldn't find next item, try to find previous item
          prev_item = @_grid_data.filterAwareGetPreviousItem(active_item_row)

          if prev_item?
            prev_path = @_grid_data.getItemPath(prev_item)

        @_grid_data.removeParent active_path, (err) =>
          if err?
            @logger.error "removeActivePath failed: #{err}"

            callCb cb, err

            releaseOpsLock()

            return

          # Make sure item removed from DOM
          @_grid_data._flushAndRebuild()

          callCb cb, err

          if next_path?
            @activatePath(next_path)
          else if prev_path?
            @activatePath(prev_path)

          # Release lock only after activation of next path to
          # avoid any chance of refering to removed path in
          # following operations
          releaseOpsLock()

    prereq: ->
      pre_requirements = 
        @_opreqActivePathLevelPermitted(@_opreqActivePathIsLeafOrHaveMultipleParents(@_opreqUnlocked(@_opreqGridReady())))

      if "active_path_level_not_permitted" of pre_requirements
        current_row = @getCurrentRow()

        grid_data = @_grid_data
        section = grid_data.getItemSection(current_row)

        if (removeSpecialCase = section.options?.permitted_depth_removeSpecialCase)? and
           removeSpecialCase.call(@, current_row)
              delete pre_requirements.active_path_level_not_permitted

      return pre_requirements
