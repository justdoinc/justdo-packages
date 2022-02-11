isShiftKeyPressed = (e) ->
  return e.originalEvent.shiftKey is true

isMetaKeyPressed = (e) ->
  return e.originalEvent.ctrlKey or e.originalEvent.metaKey

#
# Sortable helper
#
_.extend PACK.Plugins,
  multi_select:
    init: ->
      # Note: @ is the real grid_control object
      self = @

      self.container.addClass("not-multi-select")

      clearMultiSelected = ->
        $(".slick-row", self.container).removeClass "multi-selected"
        return

      clearAllMultiSelectDomChanges = ->
        clearMultiSelected()

        return

      $current_row_node = null
      $previous_row_node = null
      self.multi_select_previous_row_trail_maintainer_computation = Tracker.autorun ->
        $previous_row_node = $current_row_node

        $current_row_node = null
        if (current_row = self.getCurrentRow())?
          $current_row_node = $(self._grid.getRowNode(current_row))

        return

      $_multi_select_origin_row = null
      determineOriginRow = ->
        # Determines the correct origin, and return it
        if $_multi_select_origin_row?
          # We determined already an origin, in one of the previous clicks, nothing to do,
          # just return it (to avoid replacing it)
          return $_multi_select_origin_row

        $_multi_select_origin_row = $previous_row_node

        return $_multi_select_origin_row
      clearOriginRow = ->
        $_multi_select_origin_row = null
        
        return

      multi_select_mode_rv = new ReactiveVar(false)
      exitMultiSelectMode = ->
        clearOriginRow()
        setMultiSelectedPathsFromArray([])

        if self.isMultiSelectMode()
          # clearAllMultiSelectDomChanges() is expensive to do redundantly
          clearAllMultiSelectDomChanges()
          multi_select_mode_rv.set(false)
          updateIsConsecutive() # Will set is_consecutive_rv to false since the multi select is false
          self.container.addClass("not-multi-select")
          self.container.removeClass("multi-select")
        return
      self.exitMultiSelectMode = exitMultiSelectMode

      enterMultiSelectMode = ->
        multi_select_mode_rv.set(true)
        self.container.removeClass("not-multi-select")
        self.container.addClass("multi-select")
        return

      self.isMultiSelectMode = ->
        return multi_select_mode_rv.get()

      is_consecutive_rv = new ReactiveVar(false)
      self.isMultiSelectConsecutiveSelect = ->
        # Consecutive means - no (filter-aware) gap between the items + same indent level
        self._grid_data.invalidateOnRebuild()
        self._grid_data.filter.get() # Become reactive to filters changes

        return is_consecutive_rv.get()

      updateIsConsecutive = ->
        if not self.isMultiSelectMode()
          is_consecutive_rv.set(false)

          return

        selected_items_rows = []
        for path in multi_selected_paths
          row_index = self._grid_data.getPathGridTreeIndex(path)

          selected_items_rows.push row_index

        selected_items_rows_before_sort = selected_items_rows.slice()
        selected_items_rows.sort((a, b) -> return a - b)
        selected_items_rows_copy = EJSON.clone(selected_items_rows) # We are popping items from selected_items_rows later
        multi_selected_paths_isnt_ordered =
          EJSON.equals(selected_items_rows_before_sort, selected_items_rows)

        setConsecutiveMode = ->
          is_consecutive_rv.set(true)

          # If selected items are consecutive, ensure that they are stored in their order
          # under: multi_selected_paths (to make it easy for the developers to access
          # the first/last item)
          if not multi_selected_paths_isnt_ordered
            sorted_paths = []
            for row_index in selected_items_rows_copy
              if (item_path = self._grid_data.getItemPath(row_index))?
                sorted_paths.push item_path

            setMultiSelectedPathsFromArray(sorted_paths)

          return

        if (is_filter_enabled = self._grid_data.filter.get())
          if not (grid_tree_filter_state = self._grid_data._grid_tree_filter_state)?
            # See comment in this file: COMMENT_RE_GRID_TREE_FILTER_STATE
            return

          # We scan from the last selected_items_rows
          indent_level_of_first_item = self._grid_data.grid_tree[selected_items_rows[selected_items_rows.length - 1]][1]
          grid_tree_filter_state_pointer = selected_items_rows.pop()
          while (current_row_to_check = selected_items_rows.pop())
            # Ensure that the previous item is the previous visible item in the filtered tree
            grid_tree_filter_state_pointer -= 1
            while grid_tree_filter_state_pointer >= 0 and grid_tree_filter_state[grid_tree_filter_state_pointer][0] == 0
              grid_tree_filter_state_pointer -= 1
            if current_row_to_check != grid_tree_filter_state_pointer
              is_consecutive_rv.set(false)

              return

            if indent_level_of_first_item != self._grid_data.grid_tree[current_row_to_check][1]
              is_consecutive_rv.set(false)

              return

          setConsecutiveMode()

          return
        else # Filter mode is off
          indent_level_of_first_item = self._grid_data.grid_tree[selected_items_rows[0]][1]

          if (selected_items_rows[0] + selected_items_rows.length - 1) != selected_items_rows[selected_items_rows.length - 1]
            # Optimization, no chance of consecutive in that case
            is_consecutive_rv.set(false)

            return

          # By this point we know that the numbers are consecutive.
          for i in [selected_items_rows[0]..(selected_items_rows[0] + selected_items_rows.length - 1)]
            if self._grid_data.grid_tree[i][1] != indent_level_of_first_item
              is_consecutive_rv.set(false)

              return

          setConsecutiveMode()

          return

        return

      multi_selected_paths = []
      multi_selected_paths_dep = new Tracker.Dependency()
      getMultiSelectedPathsArray = ->
        multi_selected_paths_dep.depend()

        return multi_selected_paths

      self.getFilterPassingMultiSelectedPathsArray = ->
        self._grid_data.invalidateOnRebuild()
        self._grid_data.filter.get() # Become reactive to filters changes

        paths = []

        for path in getMultiSelectedPathsArray()
          row_index = self._grid_data.getPathGridTreeIndex(path)

          if self._grid_data.getItemPassFilter(row_index)
            paths.push path

        return paths

      setMultiSelectedPathsFromArray = (paths_array) ->
        paths_array = paths_array or []
        if _.isEmpty(paths_array) and _.isEmpty(multi_selected_paths)
          # This is to prevent infinite loop, setMultiSelectedPathsFromArray is triggering exit
          # in case of empty paths_array, and exitMultiSelectMode is calling setMultiSelectedPathsFromArray([])
          # by preventing double treatment for case we are already empty, infinite loop is prevented.
          return

        cleaned_paths_array = []
        for path in paths_array
          if (path_row_index = self._grid_data.getPathGridTreeIndex(path))?
            if self._grid_data.getItemIsCollectionItem(path_row_index)
              # Don't allow selecting non-collection items (like section items)
              cleaned_paths_array.push path

        multi_selected_paths = cleaned_paths_array
        multi_selected_paths_dep.changed()

        if _.isEmpty(multi_selected_paths)
          exitMultiSelectMode()
        else if multi_selected_paths.length == 1
          # If we exit multi select mode due to last task reached in selection - activate that task, that's the user's expectation in terms of beaviour
          self.activatePath(multi_selected_paths[0])
          exitMultiSelectMode()
        else
          enterMultiSelectMode()
          updateIsConsecutive()
          renderMultiSelectedPaths()

        return

      togglePathSelection = (path) ->
        # ASSUMES SANITIZED/VERIFIED/CORRECT INPUTS

        if not self.isMultiSelectMode()
          return

        current_selection = getMultiSelectedPathsArray()

        if path in current_selection
          setMultiSelectedPathsFromArray(_.without(current_selection, path))
        else
          current_selection.push(path)
          setMultiSelectedPathsFromArray(current_selection)

        return

      setMultiSelectedPathsFromRowsRange = (start, end) ->
        # ASSUMES SANITIZED/VERIFIED/CORRECT INPUTS
        if end < start
          swap = start
          start = end
          end = swap

        paths = []
        allowed_level = null
        for row_index in [start..end]
          if self._grid_data.getItemPassFilter(row_index)

            item_level = self._grid_data.getItemLevel(row_index)
            if not allowed_level?
              allowed_level = item_level
            else if item_level != allowed_level
              exitMultiSelectMode()
              return

            if (item_path = self._grid_data.getItemPath(row_index))?
              paths.push item_path

        setMultiSelectedPathsFromArray(paths)

        return

      updateMultiSelectedPaths = ->
        if (is_filter_enabled = self._grid_data.filter.get())
          if not (grid_tree_filter_state = self._grid_data._grid_tree_filter_state)?
            # COMMENT_RE_GRID_TREE_FILTER_STATE
            #
            # If the filter is enabled but _grid_tree_filter_state isn't set, it means the filter
            # wasn't updated yet, do nothing, another event will be triggered later in which
            # we will update the selected paths correctly.
            #
            # It happens when grid-view-change event fires following filter update, before grid-tree-filter-updated fires
            return

        updated_paths = []
        for path in getMultiSelectedPathsArray()
          if not (row_index = self._grid_data.getPathGridTreeIndex(path))?
            # Path isn't in the visible tree any more
            continue

          if is_filter_enabled
            # Check if the path still pass the filter
            if grid_tree_filter_state[row_index][0] == 0 # Path doesn't pass the filter any longer
              continue

          updated_paths.push(path)

        setMultiSelectedPathsFromArray(updated_paths)

        return

      renderMultiSelectedPaths = ->
        clearMultiSelected()

        for path in self.getFilterPassingMultiSelectedPathsArray()
          row_index = self._grid_data.getPathGridTreeIndex(path)

          self.getRowNode(row_index).addClass "multi-selected"

        return

      multi_select_exit_if_item_activated_outside_computation = null
      is_processing_meta_key = false
      self.setupExitMultiSelectHooks = ->
        APP.on "doc-esc-click", exitMultiSelectMode

        multi_select_exit_if_item_activated_outside_computation = Tracker.autorun ->
          if is_processing_meta_key
            return

          if self.isMultiSelectMode()
            if (current_path = self.getCurrentPath())?
              if current_path not in self.getFilterPassingMultiSelectedPathsArray()
                exitMultiSelectMode()

          return

        return

      self.destroyExitMultiSelectHooks = ->
        APP.off "doc-esc-click", exitMultiSelectMode

        multi_select_exit_if_item_activated_outside_computation.stop()

        return

      self.setupExitMultiSelectHooks()

      self.setupRefreshMultiSelectStateHooks = ->
        self.on "grid-tree-filter-updated", (filters_state, query) ->
          if not self.isMultiSelectMode()
            return

          updateMultiSelectedPaths()

          return

        self.on "grid-view-change", (view) ->
          if not self.isMultiSelectMode()
            return

          updateMultiSelectedPaths()

          return

        self.on "rebuild_ready", (rebuild_info) ->
          if not self.isMultiSelectMode()
            return

          updateMultiSelectedPaths()

          return

        return

      self.destroyRefreshMultiSelectStateHooks = ->
        # At the moment, nothing to destroy, all events are on the grid control object level
        return

      self.setupRefreshMultiSelectStateHooks()

      # Deal with clicks
      $(".grid-canvas", self.container).on "click", ".slick-row", (e) ->
        if $(e.target).closest(".grid-tree-control-toggle").length > 0
          # Click on expand/collapse shouldn't exit multi-select mode
          return

        if not isShiftKeyPressed(e) and not isMetaKeyPressed(e)
          exitMultiSelectMode()

          return

        # By this stage, we know that either the Shift key or the Meta key is pressed.

        # Let the autorun process the click (necessary to update $current_row_node, $previous_row_node)
        if isMetaKeyPressed(e)
          is_processing_meta_key = true
          # While we flush the click, to avoid exiting the multi-select mode due to
          # clicking outside of selection, we set the is_processing_meta_key flag to
          # true
        Tracker.flush()
        if isMetaKeyPressed(e)
          is_processing_meta_key = false

        #
        # Process meta-key press
        #
        if isMetaKeyPressed(e)
          current_row_index = null
          current_path = null
          origin_row_index = null
          origin_path = null

          if $current_row_node?
            current_row_index = self.getRowNodeIndex($current_row_node)

            if current_row_index?
              current_path = self._grid_data.getItemPath(current_row_index)

          if $previous_row_node?
            origin_row_index = self.getRowNodeIndex($previous_row_node)

            if origin_row_index?
              origin_path = self._grid_data.getItemPath(origin_row_index)

          if not self.isMultiSelectMode()
            if current_row_index? and origin_row_index? and self._grid_data.getItemPassFilter(current_row_index) and self._grid_data.getItemPassFilter(origin_row_index)
              # Current/Origin are visible, enter multi-select mode, with both

              setMultiSelectedPathsFromArray([origin_path, current_path])

              return

          if self._grid_data.getItemPassFilter(current_row_index)
            togglePathSelection(current_path)
            return

          return

        #
        # Process the shift-key press
        #
        if not ($multi_select_origin_node = determineOriginRow())?
          # We had no previously selected row, impossible to get into multi-select mode

          exitMultiSelectMode()

          return

        current_row_index = self.getRowNodeIndex($current_row_node)
        origin_row_index = self.getRowNodeIndex($multi_select_origin_node)

        if not origin_row_index?
          exitMultiSelectMode()
          return

        if not self._grid_data.getItemPassFilter(current_row_index) or not self._grid_data.getItemPassFilter(origin_row_index)
          # Current/Origin isn't visible any longer

          exitMultiSelectMode()

          return

        # By this stage, shift Key is pressed + we got an origin + origin is visible (existing and passing filter)

        if current_row_index == origin_row_index
          # Same row shift-clicked, exit
          exitMultiSelectMode()
          return

        current_path = self._grid_data.getItemPath(current_row_index)
        origin_path = self._grid_data.getItemPath(origin_row_index)
        current_parent_path = GridData.helpers.getParentPath(current_path)
        origin_parent_path = GridData.helpers.getParentPath(origin_path)

        if current_parent_path != origin_parent_path
          # Different parent consecutive select isn't supported

          exitMultiSelectMode()
          return

        # Debugging log:
        # console.log {$multi_select_origin_node, $current_row_node, $previous_row_node, current_row_index, origin_row_index}

        setMultiSelectedPathsFromRowsRange(current_row_index, origin_row_index)

        return

      return

    destroy: ->
      # Note: @ is the real grid_control object
      self = @

      self.multi_select_previous_row_trail_maintainer_computation.stop()
      self.destroyExitMultiSelectHooks()
      self.destroyRefreshMultiSelectStateHooks()

      return
