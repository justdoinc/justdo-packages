# Click event is prevent somewhere, mimic click by waiting for mousedown followed by mouseup on same row

last_mouse_down_row = null

selector = ".slick-cell:not(.active):not(.editable)"

GridControl.jquery_builtin_events.push(
  {
    args: ['mousedown', selector]
    handler: (e) ->
      last_mouse_down_row = @getEventRow(e)

      return
  }
)

GridControl.jquery_builtin_events.push(
  {
    args: ['mouseup', selector]
    handler: (e) ->
      if $(e.target).hasClass("grid-tree-control-toggle")
        # Click on the expand/collapse button shouldn't trigger row activation

        return

      if (event_row = @getEventRow(e)) != last_mouse_down_row
        return

      save_and_exit_not_prevented = @saveAndExitActiveEditor()

      if save_and_exit_not_prevented
        @activateRow(event_row, 0, false)
      else
        @logger.debug "Couldn't activate row: #{event_row}, a cell on edit mode can't be saved"
  }
)
