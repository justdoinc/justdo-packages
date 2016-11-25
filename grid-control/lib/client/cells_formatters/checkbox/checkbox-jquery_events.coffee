PACK.jquery_builtin_events.push(
  {
    # Save checkbox formatter on_change
    args: ['change', '.checkbox-formatter']
    handler: (e) ->
      cell = @_grid.getCellFromEvent(e)
      field = @getCellField cell.cell
      item = @_grid_data.getItem(cell.row)
      item_id = if item? then item._id else undefined

      query = {}
      query[field] = $(e.currentTarget).prop('checked')
      @_grid_data.collection.update item_id, {$set: query}
  }
)