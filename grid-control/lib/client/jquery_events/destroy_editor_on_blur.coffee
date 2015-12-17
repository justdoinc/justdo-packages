PACK.jquery_events.push(
  {
    # destroy current cell editor if blurred out and value didn't change
    args: ['blur', '.editor-text,input.editor-unicode-date,.tree-control-input,.tree-control-textarea,.textarea-editor,div.selector-editor']
    handler: (e) ->
      if not @__reedit_cell_after_blur_patch_applied?
        @__reedit_cell_after_blur_patch_applied = true

        @_grid.onClick.subscribe (e, args) =>
          active_cell = @_grid.getActiveCell()
          clicked_cell = args

          # If active cell clicked again, get into edit mode (won't happen without this fix)
          if active_cell? and active_cell.row == clicked_cell.row and
             active_cell.cell == clicked_cell.cell
              @_grid.editActiveCell()

      Meteor.defer =>
        if (e.currentTarget == $('.editor-text', @container).get(0)) or
           (e.currentTarget == $('.tree-control-input', @container).get(0)) or
           (e.currentTarget == $('.tree-control-textarea', @container).get(0)) or
           (e.currentTarget == $('.textarea-editor', @container).get(0))
            @saveAndExitActiveEditor()

        # Destroy selector editor only if blur isn't a result of expanding options
        if (e.currentTarget == $('div.selector-editor', @container).get(0))
          original_active_cell = @_grid.getActiveCell()
          setTimeout =>
            active_cell = @_grid.getActiveCell()

            if original_active_cell.row == active_cell.row and
               original_active_cell.cell == active_cell.cell and
               not $("div.selector-editor .dropdown-menu").is(":visible") and
               not $(e.currentTarget).is(":focus")
               # If after blur active cell remains the same (means we blurred
               # out of the grid control) and the datepicker isn't visible (the
               # blur wasn't a result of opening the date picker) and we aren't
               # focused (no reason to close) commit changes and exit editor 
              @saveAndExitActiveEditor()
          , 250

        # Destroy date editor only if blur isn't a result of opening the datepicker
        if (e.currentTarget == $('input.editor-unicode-date', @container).get(0))
          original_active_cell = @_grid.getActiveCell()
          setTimeout =>
            active_cell = @_grid.getActiveCell()

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
