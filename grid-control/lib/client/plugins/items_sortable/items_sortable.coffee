#
# Sortable helper
#
sortable = =>
  # Returns jQuery ui sortable method for grid-canvas
  $obj = $(".grid-canvas", @container)

  return $obj.sortable.apply $obj, arguments 

refresh_sortable = =>
  sortable("refresh")
  sortable("refreshPositions")

getPlaceholderIndex = (ui) =>
  placeholder_index = ui.placeholder.index()
  helper_index = ui.helper.index()

  if helper_index < placeholder_index
    # Cancel the shift to index resulted from the hidden placeholder
    placeholder_index -= 1

  return placeholder_index

_.extend PACK.Plugins,
  items_resortable:
    init: ->
      # Note: @ is the grid_control object

      options =
        # The minimal time in ms before we regard sort state as a long hover
        long_hover_threshold: .50 * 1000

      dragged_row_index = 0
      dragged_row_extended_details = null

      sort_state = {}
      initSortState = -> _.extend sort_state,
        last_changed: new Date()
        placeholder_index: null
        mouse_vs_placeholder: null # 0 means mouse on placeholder, -1 prev, 1 next
        long_hover: null
        sort_direction: 0 # 0 means we don't have direction yet, -1 up, 1 down
        copy_mode: null
        cursor_outside_grid: false

      placeholder_position = {}
      initPlaceholderPosition = -> _.extend placeholder_position,
        parent: null
        order: null
        level: null

      #
      # Manage sort_state
      #
      updateSortState = (new_state) =>
        updated = false

        if (new_state.cursor_outside_grid? and
            new_state.cursor_outside_grid != sort_state.cursor_outside_grid)
          updated = true
          sort_state.cursor_outside_grid = new_state.cursor_outside_grid

        if (new_state.placeholder_index? and
            new_state.placeholder_index != sort_state.placeholder_index) or
           (new_state.mouse_vs_placeholder? and
            new_state.mouse_vs_placeholder != sort_state.mouse_vs_placeholder) or
           (new_state.copy_mode? and
            new_state.copy_mode != sort_state.copy_mode)
          updated = true

          # find sort direction
          if sort_state.placeholder_index?
            # sort_state won't have placeholder_index first time it called
            # after sort_state init
            if new_state.placeholder_index > sort_state.placeholder_index
              sort_direction = 1 # down
            else if new_state.placeholder_index < sort_state.placeholder_index
              sort_direction = -1 # up
            else
              # Keep sort direction as is
              sort_direction = sort_state.sort_direction
          else
            # Keep sort direction as is
            sort_direction = sort_state.sort_direction

          _.extend sort_state, new_state, 
            last_changed: new Date()
            long_hover: false
            sort_direction: sort_direction
            copy_mode: new_state.copy_mode
        else if new_state.long_hover? and
                  new_state.long_hover != sort_state.long_hover
          updated = true
          # Long hover change
          _.extend sort_state, new_state,
            last_changed: new Date()

        if not updated
          # Return here if nothing changed to avoid emitting the event
          return

        ui = sortable("instance")
        @emit "rows-sort-state-updated", ui, sort_state

      longHoverMonitor = =>
        if not sort_state.long_hover and
              (new Date()) - sort_state.last_changed > options.long_hover_threshold
          updateSortState
            long_hover: true

      long_hover_monitor_interval = null
      setLongHoverMonitorInterval = =>
        if not long_hover_monitor_interval?
          long_hover_monitor_interval = setInterval longHoverMonitor, 100

      @clearLongHoverMonitorInterval = =>
        if long_hover_monitor_interval?
          clearInterval long_hover_monitor_interval
          long_hover_monitor_interval = null

      #
      # React to sort_state updates, manage placeholder_position
      #
      getRowExtendedDetails = (row_index) =>
        if not row_index?
          return null

        item = @_grid_data.grid_tree[row_index]
        [doc, level, path, expand_state] = item
        parent = GridData.helpers.getPathParentId path
        order = doc.parents[parent].order

        ext = {
          _id: doc._id
          doc: doc
          level: level
          path: path
          expand_state: expand_state
          parent: parent
          order: order,
          node: @_grid.getRowNode(row_index).rowNode
        }

        return ext

      @rows_sort_state_updated_event_handler = (ui, sort_state) =>
        # console.log "rows-sort-state-updated", ui, sort_state

        updatePlaceholderPosition = (parent, order, level) =>
          if placeholder_position.parent != parent or
                placeholder_position.order != order or
                placeholder_position.level != level
            # We use extend to use the same object
            _.extend placeholder_position,
              parent: parent
              order: order
              level: level

            # Condition above, makes sure we emit only when something changed
            @emit "rows-sort-placeholder-position-updated", ui, placeholder_position

        # Find the correct index of the items before and
        # after the placeholder - this is needed since the
        # move the sorted row shifts the positions of the other
        # rows.
        placeholder_index = sort_state.placeholder_index # just alias
        if placeholder_index == dragged_row_index
          previous_item_index = placeholder_index - 1
          next_item_index = placeholder_index + 1
        else if placeholder_index < dragged_row_index
          previous_item_index = placeholder_index - 1
          next_item_index = placeholder_index
        else if placeholder_index > dragged_row_index
          # We don't use `else` for readability
          previous_item_index = placeholder_index
          next_item_index = placeholder_index + 1

        if @_grid_data.isActiveFilter()
          # If there's an active filter, look for visible prev/next items indexes
          filter_paths = @_grid_data.getFilterPaths()

          if previous_item_index?
            while previous_item_index >= 0
              if filter_paths[previous_item_index][0] > 0 # means passing filter
                break

              previous_item_index -= 1

          while next_item_index < @_grid_data.getLength()
            if filter_paths[next_item_index][0] > 0 # means passing filter
              break

            next_item_index += 1        

        if previous_item_index < 0
          previous_item_index = null

        if next_item_index > @_grid_data.getLength() - 1
          # No next item
          next_item_index = null

        # ext stands for extended details
        ext =
          prev: getRowExtendedDetails previous_item_index
          next: getRowExtendedDetails next_item_index
          dragged: dragged_row_extended_details

        # Determine which sibling should be used as the placeholder sibling when determining new position
        determine_position_by = null # -1: previous item, 0: keep in original position; 1: next item
        if not ext.prev and not ext.next
          # console.log "CASE 0: Determine by original - no next or prev items"

          determine_position_by = 0
        else if sort_state.sort_direction == 0
          # console.log "CASE 1: Sort direction: 0 (sort just began)"
          # If sort_direction == 0, sort had just began and the user hasn't
          # moved the placeholder yet.
          if sort_state.mouse_vs_placeholder == 0 or
                (not ext.prev? and sort_state.mouse_vs_placeholder == -1) or
                (not ext.next? and sort_state.mouse_vs_placeholder == 1)
            # If cursor is inside the placeholder, or outside but there's no item outside
            # keep item in its original place
            # console.log "CASE 1.1: Original postion :: Use original; Cursor is inside the placeholder, or outside but there's no item outside"

            determine_position_by = 0
          else if sort_state.mouse_vs_placeholder == -1
            # If mouse on prev item
            # console.log "CASE 1.2: Original postion :: Use previous; Cursor on previous item"

            determine_position_by = -1
          else if sort_state.mouse_vs_placeholder == 1 # else if used for readability
            # If mouse on next item. Note: we know for sure next item exist due to a check above.
            # console.log "CASE 1.3: Original postion :: Use previous; Cursor on next item"

            determine_position_by = 1
        else if not ext.next?
          # If no next item, previous determines
          # console.log "CASE 2.1: No next item - determine by previous"

          determine_position_by = -1
        else if not ext.prev?
          # If no next item, previous determines
          # console.log "CASE 2.2: No prev item - determine by next"

          determine_position_by = 1
        else if sort_state.sort_direction == 1
          # If placeholder is being moved downwards
          # console.log "CASE 3: Placeholder moving down - next item exists"

          # Determine position based on previous item, unless cursor
          # placed on next item
          if sort_state.mouse_vs_placeholder != 1
            # console.log "CASE 3.1: Mouse isn't on next - determine by previous"

            determine_position_by = -1
          else
            # console.log "CASE 3.2: Mouse is on next - determine by next"

            determine_position_by = 1
        else if sort_state.sort_direction == -1
          # If placeholder is being moved upwards
          # console.log "CASE 4: Placeholder moving up - next item exists"

          # Determine position based on next item, unless cursor
          # placed on prev item
          if sort_state.mouse_vs_placeholder != -1
            # console.log "CASE 4.1: Mouse isn't on prev - determine by next"

            determine_position_by = 1
          else
            # console.log "CASE 4.2: Mouse is on prev - determine by prev"

            determine_position_by = -1

        parent = null
        order = null
        level = null
        if determine_position_by == 0
          parent = ext.dragged.parent
          order = ext.dragged.order
          level = ext.dragged.level
        else if determine_position_by == -1
          # Determine placeholder position by previous parent

          if ext.prev.expand_state == 1 or isNewLevelMode()
            # Expand state of 1, means previous item is a collapsed item
            # placeholder should be a child of that item -> hance level + 1
            # If we are in new-level-mode it means previous item serves
            # as our parent, even though it has no children.
            parent = ext.prev._id
            order = 0
            level = ext.prev.level + 1
          else
            parent = ext.prev.parent
            order = ext.prev.order + 1
            level = ext.prev.level
        else if determine_position_by == 1
          # Determine placeholder position by next parent
          parent = ext.next.parent
          order = ext.next.order
          level = ext.next.level

          # Note! new order must be equal to next item and not (next item -1).
          # Equal order means we push all elements starting from next by 1 and
          # placing placeholder where next was, -1 will put placeholder before
          # previous item.

        # Special case: if new position is equal to current dragged item with
        # new order == previous order + 1: use previous order. As both will
        # lead to the same result but the other option will cause redundant
        # update in the server.
        if parent == ext.dragged.parent and
            order == ext.dragged.order + 1
          order = ext.dragged.order

        if sort_state.long_hover and sort_state.mouse_vs_placeholder != 0
          # If long hover outside of placeholder
          item_under_cursor =
            if sort_state.mouse_vs_placeholder == -1 then ext.prev else ext.next

          if item_under_cursor?
            # If there's an item under the cursor
            if item_under_cursor.expand_state == 0
              # If there's a collapsed item with children under the cursor expand it
              @_grid_data.expandPath item_under_cursor.path

              @_grid_data._perform_temporal_strucutral_flush_lock_release()

              # Update dragged_row_index
              dragged_row_index = @_grid_data.getItemRowByPath(dragged_row_extended_details.path)

              refresh_sortable()
            if item_under_cursor.expand_state == -1
              # If item under cursor has no children, add placeholder as a new child
              parent = item_under_cursor._id
              order = 0
              level = item_under_cursor.level + 1

              if item_under_cursor == ext.next
                # Move placeholder to be the first child of next item
                ui.placeholder.insertAfter item_under_cursor.node

                # Update sort state to match new forced position
                _.extend sort_state,
                  placeholder_index: getPlaceholderIndex(ui)
                  mouse_vs_placeholder: 0
                  sort_direction: 1 # down to make previous item the significant

                refresh_sortable()

              # Call updateNewLevelMode to clear any existing new-level-mode before
              # setting this one (otherwise we can have some style leftovers on prev
              # parent)
              updateNewLevelMode()

              setNewLevelMode(item_under_cursor.node)

        updateNewLevelMode()

        return updatePlaceholderPosition parent, order, level

      @on "rows-sort-state-updated", @rows_sort_state_updated_event_handler

      #
      # React to placeholder_position updates, update ui accordingly
      #
      @rows_sort_placeholder_position_updated = (ui, placeholder_position) =>
        # Update placeholder html with its current position level
        setPlaceholderHtml(ui, placeholder_position.level)

      @on "rows-sort-placeholder-position-updated", @rows_sort_placeholder_position_updated

      #
      # Placeholder html generators
      #
      manipulatedGridRender = (customizations, renderOp) =>
        # Perform render operations specified in the renderOp
        # function where the grid data is manipulated according
        # to customizations object

        # Once renderOp is done running, remove all data
        # customizations.

        # Reutrns renderOp output

        realGetItemLevel = @_grid_data.getItemLevel

        # Apply customizations

        # Manipulated levels
        if customizations.items_levels?
          @_grid_data.getItemLevel = (index) -> customizations.items_levels[index]

        # call renderOp
        output = renderOp()

        # Bring back original methods
        @_grid_data.getItemLevel = realGetItemLevel

        return output

      getDraggedRowJqueryObj = => @_grid.getRowJqueryObj dragged_row_index

      getCustomLevelRowHtml = (row_id, level) =>
        data_customizations =
          items_levels: {}
        data_customizations.items_levels[row_id] = level

        row_html = manipulatedGridRender data_customizations, =>
          @_grid.getRowHtml(row_id)

        return row_html

      getDraggedRowHtml = (force_level) =>
        if force_level?
          getCustomLevelRowHtml(dragged_row_index, force_level)
        else
          @_grid.getRowHtml(dragged_row_index)

      setPlaceholderHtml = (ui, force_level) =>
        ui.placeholder.html(getDraggedRowHtml(force_level))

      invalidateRowCells = (row_id) =>
        @_grid.cleanUpAndRenderCells
          top: row_id
          bottom: row_id
          leftPx: 0
          rightPx: -1

        @_grid.cleanUpAndRenderCells
          top: row_id
          bottom: row_id
          leftPx: 0
          rightPx: 99999

      forceCustomLevelRowCellsInvalidation = (row_id, level) =>
        data_customizations =
          items_levels: {}
        data_customizations.items_levels[row_id] = level

        manipulatedGridRender data_customizations, =>
          invalidateRowCells(row_id)

      disableDraggedRowEditing = =>
        getDraggedRowJqueryObj().addClass("slick-edit-disabled")

      enableDraggedRowEditing = =>
        getDraggedRowJqueryObj().removeClass("slick-edit-disabled")

      markDraggedRowWaitingForServer = =>
        getDraggedRowJqueryObj().addClass("sortable-waiting-server")

      unmarkDraggedRowWaitingForServer = =>
        getDraggedRowJqueryObj().removeClass("sortable-waiting-server")

      isCopyModeEvent = (event) => event.altKey || event.ctrlKey # alt is for Mac, ctrl is for pc

      #
      # New level mode (When placeholder demonstrates result of adding an item as a child of another item)
      #
      # holds the placeholder position for the new-level-mode, or null if not in
      # new-level-mode
      _new_level_mode = null
      _new_level_mode_parent_class = "sortable-new-level-mode-parent"
      setNewLevelMode = (new_parent_node) =>
        # Enter into new-level-mode with current placeholder position.
        # Mode will exit as soon as updateNewLevelMode() will be called when
        # placeholder is in a different position.
        # new_parent_node is needed only for style purposes, we don't record it for
        # later use
        _new_level_mode = sort_state.placeholder_index

        $(new_parent_node).addClass _new_level_mode_parent_class
        
      isNewLevelMode = => _new_level_mode?

      updateNewLevelMode = (force_exit=false) =>
        if _new_level_mode != sort_state.placeholder_index or force_exit
          _new_level_mode = null

          $(".#{_new_level_mode_parent_class}", @container).removeClass(_new_level_mode_parent_class)

      #
      # Cancel mode (When cursor is outside of grid or esc is pressed)
      #
      _cancel_mode = false
      _cancel_mode_class = "sortable-cancel-mode"
      _setCancelMode = =>
        if not isCancelMode()
          # Enter into cancel-mode.
          _cancel_mode = true

          @container.addClass _cancel_mode_class
        
      isCancelMode = => _cancel_mode

      _unsetCancelMode = =>
        if isCancelMode()
          # Exit cancel-mode.
          _cancel_mode = false

          @container.removeClass _cancel_mode_class

      _refreshCancelMode = =>
        if _esc_key_down or not _cursor_within_grid
          _setCancelMode()
        else
          _unsetCancelMode()

      _esc_key_down = false
      _escKeyDownHandler = (e) ->
        if e.keyCode == 27
          if _esc_key_down != true
            _esc_key_down = true

            _refreshCancelMode()

      _escKeyUpHandler = (e) ->
        if e.keyCode == 27
          if _esc_key_down != false
            _esc_key_down = false

            _refreshCancelMode()

      _cursor_within_grid = true
      _sortHandlerCancelDetection = (e) =>
        container_offset = @container.offset()
        container_top = container_offset.top
        container_bottom = container_top + @container.outerHeight()
        container_left = container_offset.left
        container_right = container_left + @container.outerWidth()

        within_grid = null
        if container_top <= e.pageY <= container_bottom and
              container_left <= e.pageX <= container_right
          within_grid = true
        else
          within_grid = false

        if _cursor_within_grid != within_grid
          # If changed
          _cursor_within_grid = within_grid

          _refreshCancelMode()

      initCancelTracker = =>
        $(document).on 'keydown', _escKeyDownHandler
        $(document).on 'keyup', _escKeyUpHandler
        @container.on 'sort', _sortHandlerCancelDetection

        _esc_key_down = false
        _cursor_within_grid = true
        _cancel_mode = false

      clearCancelTracker = =>
        $(document).off 'keydown', _escKeyDownHandler
        $(document).off 'keyup', _escKeyUpHandler
        @container.off 'sort', _sortHandlerCancelDetection

        _unsetCancelMode()

      #
      # Sortable
      #
      sortable
        handle: ".cell-handle"
        cursor: "grabbing"
        axis: "y"
        distance: 5

        beforeStart: (event, ui) =>
          # Note: Must find dragged_row_index beforeStart and not in start
          # since the placeholder method will be called before start (!)
          dragged_row_index = ui.item.index()
          dragged_row_extended_details = getRowExtendedDetails dragged_row_index

          # Attempt to commit current active editor changes if false is
          # returned (op failed), prevent sorting.
          can_start = @saveAndExitActiveEditor()

          return can_start

        start: (event, ui) =>
          # Don't allow grid data updates while sorting to avoid getting
          # dragged item, its information, and actual DOM element to
          # get out of-sync with the grid.
          @_grid_data._lock_flush()

          initSortState()
          initCancelTracker()
          initPlaceholderPosition()

          # If dragging an expanded item - collapse it
          if dragged_row_extended_details.expand_state == 1
            @_grid_data.collapsePath dragged_row_extended_details.path
            @_grid_data._flush() # Flush to collapse immediately and have
                                 # the expanded state item replaced with the
                                 # collapsed state one - which will be used
                                 # as sortable's active and helper item
                                 # instead of the original one.

            # Once grid_control finish updating dom with collapsed state
            # The original item is removed and the collapsed state item is
            # created instead of it.
            $dragged_row = @_grid.getRowJqueryObj(dragged_row_index)

            # Trick jQuery ui to regard the collapsed state item
            # as both the originaly dragged item and the helper.
            $dragged_row.addClass("ui-sortable-helper")
            sortable("instance").currentItem = $dragged_row
            sortable("instance").helper = $dragged_row

            refresh_sortable()

          # Add a mark to the placeholder
          ui.placeholder.addClass("sortable-placeholder")

          # Update the placeholder -> we are required to do it also here
          # (and not just in placeholder element code below) due to a
          # bug/quirk in jquery-ui
          setPlaceholderHtml(ui)

          updateSortState
            placeholder_index: dragged_row_index
            mouse_vs_placeholder: 0
            copy_mode: isCopyModeEvent(event)

          setLongHoverMonitorInterval()

        placeholder:
          element: (clone, ui) => getDraggedRowHtml()
          update: -> return undefined

        sort: (event, ui) =>
          placeholder_index = getPlaceholderIndex(ui)

          # Find mouse position relative to placeholder
          placeholder_offset_top = ui.placeholder.offset().top
          mouse_vs_placeholder = null
          if event.pageY < placeholder_offset_top
            mouse_vs_placeholder = -1 # Mouse is on item previous to placeholder
          else if event.pageY < placeholder_offset_top + ui.placeholder.outerHeight()
            mouse_vs_placeholder = 0 # Mouse is on placeholder
          else
            mouse_vs_placeholder = 1 # Mouse is on item previous to placeholder

          updateSortState
            placeholder_index: placeholder_index
            mouse_vs_placeholder: mouse_vs_placeholder
            copy_mode: isCopyModeEvent(event)

        stop: (event, ui) =>
          # Save cancel state before clearing it
          is_cancel_mode = isCancelMode()

          clearCancelTracker()

          if is_cancel_mode
            # Cancel and release flush
            sortable("cancel")

            @_grid_data._release_flush()
          else if dragged_row_extended_details.parent == placeholder_position.parent and
                dragged_row_extended_details.order == placeholder_position.order
            # If position didn't change

            # In the case where filters are applied, there might be situations in
            # which item's position remains the same from the filtered prespective
            # but the dom actually changed, in which case, we won't have a tree flush
            # since nothing changed. But next drag will have corrupted value for the
            # dragged item index. 
            sortable("cancel")

            # Just release flush
            @_grid_data._release_flush()
          else
            # If position changed

            # Render the original dragged item dom so its rendered level will be
            # the new level
            forceCustomLevelRowCellsInvalidation(dragged_row_index, placeholder_position.level)

            disableDraggedRowEditing()

            dragged_row_path = dragged_row_extended_details.path

            new_position = _.extend {}, placeholder_position
            delete new_position.level

            # Disable sortable while waiting for server until we update the tree
            # to its new structure.
            markDraggedRowWaitingForServer()
            sortable("disable")
            @_grid_data.movePath dragged_row_path, new_position, (err) =>
              if err
                sortable("cancel")

                invalidateRowCells(dragged_row_index)

                @logger.debug "Items-sortable: Move operation failed - grid state reverted"
              else
                # If succeed and dropped into a new level - expand parent
                if isNewLevelMode()
                  parent_details =
                    getRowExtendedDetails @_grid.getRowFromNode($(".#{_new_level_mode_parent_class}", @container).get(0))

                  @_grid_data.expandPath parent_details.path, true # true means force expansion (item have no children before flush released, so it's required)

              # force exit from new-level-mode (will do nothing if we're not in new-level-mode)
              updateNewLevelMode(true)

              # XXX flush won't replace original row if the actual position hasn't
              # changed
              unmarkDraggedRowWaitingForServer()
              enableDraggedRowEditing()

              # Release flush and flush right-away before re-enabling sortable
              @_grid_data._release_flush()
              @_grid_data._flush()
              sortable("enable")

          @clearLongHoverMonitorInterval()
          # clear reference to grid item to let gc get rid of it if needed.
          dragged_row_extended_details = null

    destroy: ->
      @rows_sort_placeholder_position_updated 
      if @rows_sort_state_updated_event_handler?
        @off "rows-sort-state-updated", @rows_sort_state_updated_event_handler

      if @rows_sort_placeholder_position_updated?
        @off "rows-sort-placeholder-position-updated", @rows_sort_placeholder_position_updated

      @clearLongHoverMonitorInterval()

      if sortable("instance")?
        sortable("destroy")
