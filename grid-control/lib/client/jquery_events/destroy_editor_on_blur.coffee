PACK.jquery_events.push(
  {
    # destroy current cell editor if blurred out and value didn't change
    args: ['blur', 'input.editor-text,input.editor-unicode-date,input.tree-control-editor-input']
    handler: (e) ->
      if not @__reedit_cell_after_blur_patch_applied?
        @__reedit_cell_after_blur_patch_applied = true

        @_grid.onClick.subscribe (e, args) =>
          active_cell = @_grid.getActiveCell()
          clicked_cell = args

          # If active cell clicked again, get into edit mode (won't happen without this fix)
          if active_cell.row == clicked_cell.row and
             active_cell.cell == clicked_cell.cell
              @_grid.editActiveCell()

      Meteor.defer =>
        if (e.currentTarget == $('input.editor-text', @container).get(0)) or
           (e.currentTarget == $('input.tree-control-editor-input', @container).get(0))
            @_grid.getEditorLock().commitCurrentEdit()

        # Destroy date editor only if blur isn't a result of opening the datepicker
        if (e.currentTarget == $('input.editor-unicode-date', @container).get(0))
          setTimeout =>
            if not $(".ui-datepicker").is(":visible")
              @_grid.getEditorLock().commitCurrentEdit()
          , 50
  }
)
