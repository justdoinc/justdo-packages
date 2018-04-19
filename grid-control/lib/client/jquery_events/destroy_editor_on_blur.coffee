editor_cells_selectors = [
  '.editor-text'
  'input.editor-unicode-date'
  '.tree-control-input'
  '.tree-control-textarea'
  '.textarea-editor'
  'div.selector-editor'
  '.cfld-editor-textarea'
].join(",")

logger_prefix = "jQuery plugin - destroy-editor-on-blur:"
GridControl.jquery_builtin_events.push(
  {
    # destroy current cell editor if blurred out and value didn't change
    args: ['blur', editor_cells_selectors]
    handler: (e) ->

      currentCell = =>
        return @_grid.getActiveCell()
      original_active_cell = currentCell()
      activeCellSameAsOriginal = =>
        active_cell = currentCell()

        if original_active_cell.row == active_cell.row and
           original_active_cell.cell == active_cell.cell
          return true

        return false

      saveAndExitIfSameActiveCellPostBlur = =>
        # If after the blur event processing by us
        # and by slick-grid, same active cell persist
        # try to save and exit (will fail if the cell
        # contains invalid data)
        Meteor.defer =>
          if activeCellSameAsOriginal()
            @logger.debug "#{logger_prefix} Attempting to exit persistent post-blur active cell"
            @saveAndExitActiveEditor()

      if (e.currentTarget == $('.editor-text', @container).get(0)) or
         (e.currentTarget == $('.tree-control-input', @container).get(0)) or
         (e.currentTarget == $('.tree-control-textarea', @container).get(0)) or
         (e.currentTarget == $('.cfld-editor-textarea', @container).get(0)) or
         (e.currentTarget == $('.textarea-editor', @container).get(0))
          saveAndExitIfSameActiveCellPostBlur()

          return

      # Destroy selector editor only if blur isn't a result of expanding options
      if (e.currentTarget == $('div.selector-editor', @container).get(0))
        # We defer, so the new focused element will be determined
        Meteor.defer =>
          active_cell = @_grid.getActiveCell()

          if active_cell?
            if original_active_cell.row == active_cell.row and
               original_active_cell.cell == active_cell.cell
              # Only if same active cell, still relevant

              bootstrap_select_item_clicked = $(":focus").closest(".bootstrap-select").length != 0
              if not bootstrap_select_item_clicked
                # Focused went out of selector, exit
                @cancelAndExitActiveEditor()

        # Save and exit on any change request
        select_picker_obj = $(e.currentTarget).data("this")
        select_picker_obj?.$element?.on "change-request-processed", =>
          @saveAndExitActiveEditor()

      Meteor.defer =>
        # Destroy date editor only if blur isn't a result of opening the datepicker
        if (e.currentTarget == $('input.editor-unicode-date', @container).get(0))
          original_active_cell = @_grid.getActiveCell()
          setTimeout =>
            if not @_grid?
              # Grid might not exist at that point anymore
              return

            active_cell = @_grid.getActiveCell()

            if active_cell?
              if original_active_cell.row == active_cell.row and
                 original_active_cell.cell == active_cell.cell and
                 not $(".ui-datepicker").is(":visible") and
                 not $(e.currentTarget).is(":focus")
                 # If after blur active cell remains the same (means we blurred
                 # out of the grid control) and the datepicker isn't visible (the
                 # blur wasn't a result of opening the date picker) and we aren't
                 # focused (no reason to close) commit changes and exit editor 
                @saveAndExitActiveEditor()
          , 250
  }
)
