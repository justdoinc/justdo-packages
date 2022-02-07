isShiftKeyPressed = (e) ->
  return e.originalEvent.shiftKey is true

clearMultiSelected = ->
  $(".slick-row").removeClass "multi-selected"
  return

clearAllMultiSelectDomChanges = ->
  clearMultiSelected()

  # # Enable unused project-operations-button
  # $("#ticket-entry").removeClass "disabled"
  # $("#add-sibling-task").removeClass "disabled"
  # $("#add-sub-task").removeClass "disabled"
  # $("#duplicate-active-item").removeClass "disabled"
  # $("#change-row-style").removeClass "disabled"

  # # Add old ID
  # $("#multi-remove-task").attr "id", "remove-task"
  # $("#multi-move-left").attr "id", "move-left"
  # $("#multi-move-right").attr "id", "move-right"
  # $("#multi-move-up").attr "id", "move-up"
  # $("#multi-move-down").attr "id", "move-down"

  return

#
# Sortable helper
#
_.extend PACK.Plugins,
  multi_select:
    init: ->
      # Note: @ is the real grid_control object
      self = @

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
        return 

      enterMultiSelectMode = ->
        multi_select_mode_rv.set(true)
        return

      self.isMultiSelectMode = ->
        return multi_select_mode_rv.get()

      self.isMultiSelectConsecutiveSelect = ->
        self._grid_data.invalidateOnRebuild()
        self._grid_data.filter.get() # Become reactive to filters changes

        # XXX when we'll allow non-consecutive selection, this one will be a reactive resource
        # That will return false if the selection isn't consecutive
        
        return true

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

        multi_selected_paths = paths_array
        multi_selected_paths_dep.changed()

        if _.isEmpty(multi_selected_paths)
          exitMultiSelectMode()
        else
          enterMultiSelectMode()
          renderMultiSelectedPaths()

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

      renderMultiSelectedPaths = ->
        clearMultiSelected()

        for path in self.getFilterPassingMultiSelectedPathsArray()
          row_index = self._grid_data.getPathGridTreeIndex(path)

          self.getRowNode(row_index).addClass "multi-selected"

        return

      self.setupExitMultiSelectHooks = ->
        APP.on "doc-esc-click", exitMultiSelectMode

        return

      self.destroyExitMultiSelectHooks = ->
        APP.off "doc-esc-click", exitMultiSelectMode

        return

      self.setupExitMultiSelectHooks()

      # Deal with clicks
      $(".grid-canvas", self.container).on "click", ".slick-row", (e) ->
        if not isShiftKeyPressed(e)
          exitMultiSelectMode()

          return

        # By this stage, we know that the Shift key is pressed.

        # Let the autorun process the click (necessary to update $current_row_node, $previous_row_node)
        Tracker.flush()

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

      return
