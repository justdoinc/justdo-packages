PACK.jquery_events.push(
  {
    # destroy current cell editor if blurred out and value didn't change
    args: ['blur', 'input.editor-text']
    handler: (e) ->
      Meteor.defer =>
        if e.currentTarget == $('input.editor-text', @container).get(0)
          editor_value = @_grid.getCellEditor().getValue()
          current_cell = @_grid.getCellFromEvent(e)
          saved_value = @getCellStoredValue(current_cell.row, current_cell.cell)

          if (editor_value == saved_value) or (not(saved_value?) and editor_value == "")
            @_grid.getEditorLock().cancelCurrentEdit()
  }
)
