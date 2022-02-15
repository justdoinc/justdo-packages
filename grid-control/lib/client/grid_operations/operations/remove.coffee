callCb = PACK.helpers.callCb

_.extend PACK.GridOperations,
  removeActivePath:
    op: (cb) ->
      @_performLockingOperation (releaseOpsLock, timedout) =>
        active_path = @getCurrentPath()
        active_item_row = @getCurrentRow()

        active_item_section = @_grid_data.getItemSection(active_item_row)
        if active_item_section.id == "my-direct-tasks"
          # Special case for the my-direct-tasks section
          # replace the /my-direct-task/ part of the path with the actual
          # parent we want to remove.
          active_path =
            active_path.replace(active_item_section.path, "/direct:#{Meteor.userId()}/")

        # find next/prev paths
        next_path = prev_path = null
        
        next_item = @_grid_data.filterAwareGetNextItem(active_item_row)
        prev_item = @_grid_data.filterAwareGetPreviousItem(active_item_row)

        if next_item?
          next_path = @_grid_data.getItemPath(next_item)

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

          active_level = GridData.helpers.getPathLevel(active_path)

          if next_path? or prev_path?
            # If at least one of next/prev paths exists, decide which one to pick
            if not next_path?
              @activatePath(prev_path)
            else if not prev_path?
              @activatePath(next_path)

            prev_item_level = GridData.helpers.getPathLevel(prev_path)
            next_item_level = GridData.helpers.getPathLevel(next_path)

            if active_level == next_item_level
              @activatePath(next_path)
            else
              @activatePath(prev_path)

          # Release lock only after activation of next path to
          # avoid any chance of refering to removed path in
          # following operations
          releaseOpsLock()

    prereq: ->
      pre_requirements = @_opreqActivePathIsLeafOrHaveMultipleParents(@_opreqUnlocked(@_opreqGridReady()))
      pre_requirements = @_opreqActivePathLevelPermitted(pre_requirements, "remove")

      return pre_requirements
