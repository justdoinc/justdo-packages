# Note: @ will be assigned as the grid_control object for both op and prereq

callCb = PACK.helpers.callCb

_.extend PACK.GridOperations,
  addItem:
    op: (absolute_path, fields, add_as_child = false, cb) ->
      if not fields?
        fields = {}

      op = "addSibling"
      if add_as_child
        op = "addChild"

      section = @_grid_data.getPathSection(absolute_path)
      relative_path = section.section_manager.relPath(absolute_path)

      @_performLockingOperation (releaseOpsLock, timedout) =>
        @_grid_data[op] relative_path, fields, (err, new_item_id, new_item_relative_path) =>
          if err?
            @logger.error "addChild failed: #{err}"

            callCb cb, err

            releaseOpsLock()

            return

          new_item_absolute_path = section.section_manager.absPath(new_item_relative_path)

          # Needed so the filter tracker computation to process immediately
          Tracker.flush()

          if add_as_child
            # Mark parent as expanded (in case it isn't yet) before adding the child
            # to the tree - this will allow to show the result in one flush
            # instead of two (one for add, one for expand), and as a result
            # the UX will be much faster and smooth.

            # true means force expansion (path might have no children before flush,
            # so it's required)
            @_grid_data.expandPath absolute_path

          # Flush to make sure the item is in the tree DOM
          # Required for pathPassFilter to work proprely
          @_grid_data._flushAndRebuild()

          if not @_grid_data.pathPassFilter(new_item_absolute_path)
            # Force new item to show even if filtered
            @forceItemsPassCurrentFilter new_item_id
            # XXX, I refrain from touching this working code, but starting from the version this
            # comment is written, @forceItemsPassCurrentFilter, now can get a callback as its
            # last parameter that takes care of flushing, it doesn't take care of 
            # @_grid_data._flushAndRebuild(), you might want to use it in the future, but do so
            # carefully. Daniel C.
            #
            # Note, that if a callback is not passed to @forceItemsPassCurrentFilter it won't
            # call Tracker.flush().

            Tracker.flush() # Needed so the filter tracker computation
                            # which depends on grid_data.filter_independent_items
                            # as a reactive resource, will immediately update 
                            # @_filter_collection_items_ids and @_grid_tree_filter_state so they'll
                            # be available for the grid_data.flush before
                            # entering edit mode (which block all grid_data.flush)

            # Flush to make sure the item is in the tree DOM
            @_grid_data._flushAndRebuild()

          @editPathCell new_item_absolute_path, 0

          callCb cb, err, new_item_id, new_item_absolute_path

          # Release lock only after activation of new path to
          # avoid any chance of refering to previous path in
          # following operations
          releaseOpsLock()

    prereq: -> @_opreqNotMultiSelectMode(@_opreqUnlocked(@_opreqGridReady()))

  addSubItem:
    op: (fields, cb) -> @addItem @getCurrentPath(), fields, true, cb
    prereq: -> @_opreqNotMultiSelectMode(@_opreqActivePathChildrenLevelPermitted(@_opreqActivePathIsCollectionItem(@addItem.prereq())))

  addSiblingItem:
    op: (fields, cb) ->
      active_path = @getCurrentPath()

      if active_path?
        @addItem active_path, fields, false, cb
      else
        # The prereq promise us the following exist if there's no active_path
        tree_root_item_id = @_grid_data.section_path_to_section["/"].section_manager.options.tree_root_item_id

        tree_root_item_path = "/"
        if tree_root_item_id != "0"
          tree_root_item_path += tree_root_item_id + "/"

        @addItem tree_root_item_path, fields, true, cb

    prereq: ->
      if not _.isEmpty(pre_req = @_opreqNotMultiSelectMode())
        return pre_req

      active_path = @getCurrentPath()

      if active_path?
        return @_opreqActivePathLevelPermitted(@_opreqActivePathIsCollectionItem(@addItem.prereq()))
      else
        # If there's no active item, check whether there's a section under the root path
        # if there is, check whether it is of type is of type
        if not _.isEmpty(add_item_prereq = @addItem.prereq())
          return add_item_prereq
        
        if not ("/" of @_grid_data.section_path_to_section)
          return {no_item_selected_no_section_on_root: ""}

        if @_grid_data.section_path_to_section["/"].section_manager.constructor != GridData.sections_managers.DataTreeSection
          return {root_path_section_isnt_data_tree_type: ""}

        return {}
