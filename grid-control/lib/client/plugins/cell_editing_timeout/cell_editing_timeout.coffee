_.extend PACK.Plugins,
  cell_editing_interval:
    init: ->
      # Note: @ is the grid_control object

      cell_editing_interval_id = null
      cell_editing_interval_ms = 1000
      cell_editing_timeout_ms = 45 * 1000 # timeout after 45 seconds

      @_setCellEditingInterval = (current_editor) =>
        if cell_editing_interval_id?
          @logger.debug "Cell editing interval already set"

          return

        @logger.debug "Set cell editing interval"

        getEditorValue = -> current_editor.getValue()
        getCurrentTime = -> new Date()

        last_change_time = getCurrentTime()
        last_value = getEditorValue()

        cell_editing_interval_id = setInterval =>
          current_time = getCurrentTime()
          current_value = getEditorValue()

          if current_value != last_value
            last_change_time = current_time
            last_value = current_value

          time_since_last_change = current_time - last_change_time
          if time_since_last_change > cell_editing_timeout_ms
            @saveAndExitActiveEditor()

        , cell_editing_interval_ms

        return

      @_clearCellEditingInterval = =>
        if not cell_editing_interval_id?
          @logger.debug "No cell editing interval to clear"

          return

        @logger.debug "Clear cell editing interval"

        clearInterval(cell_editing_interval_id)

        cell_editing_interval_id = null

        return

      @_grid.onEditCell.subscribe (e, edit_req) =>
        @_setCellEditingInterval(edit_req.currentEditor)

        return

      @_grid.onCellEditorDestroy.subscribe =>
        @_clearCellEditingInterval()

        return

    destroy: ->
      @_clearCellEditingInterval()

      return