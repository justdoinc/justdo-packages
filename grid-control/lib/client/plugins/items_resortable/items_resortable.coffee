_.extend PACK.Plugins,
  items_resortable:
    init: ->
      # Note: @ is the grid_control object

      options =
        # The minimal time in ms before we regard sort state as a long hover
        long_hover_threshold: 2 * 1000

      dragged_row_index = 0
      dragged_row_grid_tree_item = null

      sort_state = {}
      initSortState = -> _.extend sort_state,
        last_changed: new Date()
        placeholder_index: null
        mouse_vs_placeholder: null # 0 means mouse on placeholder, -1 prev, 1 next
        long_hover: null
        sort_direction: 0 # 0 means we don't have direction yet, -1 up, 1 down

      placeholder_position = {}
      initPlaceholderPosition = -> _.extend placeholder_position,
        parent: null
        order: null
        level: null

      #
      # Manage sort_state
      #
      updateSortState = (new_state) =>
        if (new_state.placeholder_index? and
            new_state.placeholder_index != sort_state.placeholder_index) or
           (new_state.mouse_vs_placeholder? and
            new_state.mouse_vs_placeholder != sort_state.mouse_vs_placeholder)
          # Position update

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
        else if new_state.long_hover? and
                  new_state.long_hover != sort_state.long_hover
          # Long hover change
          _.extend sort_state, new_state,
            last_changed: new Date()
        else
          # Return here if nothing changed to avoid emitting the event
          return

        ui = $(".grid-canvas", @container).sortable("instance")
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
          doc: doc
          level: level
          path: path
          expand_state: expand_state
          parent: parent
          order: order
        }

        return ext

      @rows_sort_state_updated_event_handler = (ui, sort_state) =>
        console.log "rows-sort-state-updated", ui, sort_state

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

        if sort_state.placeholder_index == 0
          # First item
          return updatePlaceholderPosition("0", 0, 0)

        # Find the correct index of the items before and
        # after the placeholder - this is needed since the
        # move the sorted row shifts the positions of the other
        # rows.
        placeholder_index = sort_state.placeholder_index # just alias
        if placeholder_index == dragged_row_index
          # No need to worry about first item taken care of above
          previous_item_index = placeholder_index - 1
          next_item_index = placeholder_index + 1
        else if placeholder_index < dragged_row_index
          previous_item_index = placeholder_index - 1
          next_item_index = placeholder_index # The placeholder occupy the original position of the next item
        else if placeholder_index > dragged_row_index
          # We don't use `else` for readability
          previous_item_index = placeholder_index # The placeholder occupy the original position of the next item
          next_item_index = placeholder_index + 1

        if next_item_index > @_grid_data.getLength() - 1
          # No next item
          next_item_index = null

        # ext stands for extended details
        ext =
          prev: getRowExtendedDetails previous_item_index
          next: getRowExtendedDetails next_item_index
          dragged: getRowExtendedDetails dragged_row_index

        # Determine whether the previous or next item should be placeholder sibling
        determine_position_by_prev = null
        if sort_state.sort_direction == 0
          # If sort_direction == 0, sort had just began and the user hasn't
          # moved the placeholder yet.
          if sort_state.mouse_vs_placeholder == 0
            # As long as cursor doesn't touch prev/next item - keep item in
            # its original place
            return updatePlaceholderPosition(ext.dragged.parent, ext.dragged.order, ext.dragged.level)

          if not next_item_index? or sort_state.mouse_vs_placeholder == -1
            # If there's no next item, or mouse on prev item
            determine_position_by_prev = true
          else # there's next item cursor is hovering on it (sort_state.mouse_vs_placeholder == 1)
            determine_position_by_prev = false
        else if not next_item_index?
          # If no next item, previous determines
          determine_position_by_prev = true
        else if sort_state.sort_direction == 1
          # If placeholder is being moved downwards

          # Determine position based on previous item, unless cursor
          # placed on next item
          determine_position_by_prev = true
          if sort_state.mouse_vs_placeholder == 1
            determine_position_by_prev = false
        else if sort_state.sort_direction == -1
          # If placeholder is being moved upwards

          # Determine position based on next item, unless cursor
          # placed on prev item
          determine_position_by_prev = false
          if sort_state.mouse_vs_placeholder == -1
            determine_position_by_prev = true

        if determine_position_by_prev
          # Determine placeholder position by previous parent
          parent_by_previous = null
          order_by_previous = null
          level_by_previous = null
          if ext.prev.expand_state == 1
            # Expand state of 1, means previous item is a collapsed item
            # placeholder should be a child of that item -> hance level + 1
            parent_by_previous = ext.prev.doc._id
            order_by_previous = 0
            level_by_previous = ext.prev.level + 1
          else
            parent_by_previous = ext.prev.parent
            order_by_previous = ext.prev.order + 1
            level_by_previous = ext.prev.level

          return updatePlaceholderPosition(parent_by_previous, order_by_previous, level_by_previous)
        else
          # Determine placeholder position by next parent
          parent_by_next = ext.next.doc._id
          order_by_next = ext.next.order
          level_by_next = ext.next.level

          return updatePlaceholderPosition(parent_by_next, order_by_next, level_by_next)

      @on "rows-sort-state-updated", @rows_sort_state_updated_event_handler

      #
      # React to placeholder_position updates, update ui accordingly
      #
      @rows_sort_placeholder_position_updated = (ui, placeholder_position) =>
        # Update placeholder html with its current position level
        setPlaceholderHtml(ui, placeholder_position.level)

        console.log "PLACEHOLDER POSITION CHANGED", placeholder_position
      @on "rows-sort-placeholder-position-updated", @rows_sort_placeholder_position_updated

      #
      # Placeholder html generators
      #
      getCustomLevelRowHtml = (row_id, level) =>
        # A hack to force the rendering of row_id in a specific level
        realGetItemLevel = @_grid_data.getItemLevel
        @_grid_data.getItemLevel = -> level
        html = @_grid.getRowHtml(row_id)
        @_grid_data.getItemLevel = realGetItemLevel

        return html

      getDraggedRowHtml = (force_level) =>
        if force_level?
          getCustomLevelRowHtml(dragged_row_index, force_level)
        else
          @_grid.getRowHtml(dragged_row_index)

      setPlaceholderHtml = (ui, force_level) =>
        ui.placeholder.html(getDraggedRowHtml(force_level))

      #
      # Sortable
      #
      $(".grid-canvas", @container).sortable
        handle: ".cell-handle"
        cursor: "move"
        axis: "y"
        distance: 5
        start: (e, ui) =>
          initSortState()
          initPlaceholderPosition()

          dragged_row_index = ui.item.index()
          dragged_row_grid_tree_item = @_grid_data.grid_tree[dragged_row_index]

          # Update the placeholder -> we are required to do it also here
          # (and not just in placeholder element code below) due to a
          # bug/quirk in jquery-ui
          setPlaceholderHtml(ui)

          updateSortState
            placeholder_index: dragged_row_index
            mouse_vs_placeholder: 0

          setLongHoverMonitorInterval()

        placeholder:
          element: (clone, ui) => getDraggedRowHtml()
          update: -> return undefined

        sort: (event, ui) =>
          placeholder_index = ui.placeholder.index()
          helper_index = ui.helper.index()

          if helper_index < placeholder_index
            # Cancel the shift to index resulted from the hidden placeholder
            placeholder_index -= 1

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

        stop: (event, ui) =>
          @clearLongHoverMonitorInterval()
          # clear reference to grid item to let gc get rid of it if needed.
          dragged_row_grid_tree_item = null

    destroy: ->
      @rows_sort_placeholder_position_updated 
      if @rows_sort_state_updated_event_handler?
        @off "rows-sort-state-updated", @rows_sort_state_updated_event_handler

      if @rows_sort_placeholder_position_updated?
        @off "rows-sort-placeholder-position-updated", @rows_sort_placeholder_position_updated

      @clearLongHoverMonitorInterval()

      if $(".grid-canvas", @container).sortable("instance")?
        $(".grid-canvas", @container).sortable("destroy")
