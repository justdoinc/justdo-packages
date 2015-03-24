PACK.jquery_events.push(
  {
    # Activate row on click on row handle
    args: ['click', '.cell-handle']
    handler: (e) ->
      handle_cell = @_grid.getCellFromEvent(e)
      @_grid.setActiveCell(handle_cell.row, handle_cell.cell)
  }
)
