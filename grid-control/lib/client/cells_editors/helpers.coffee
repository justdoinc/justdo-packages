helpers = PACK.EditorsHelpers

_.extend helpers,
  callFormatter: (formatter_name, editor_args) ->
  	# Get the output of formatter for current editor_args

    active_cell = editor_args.grid.getActiveCell()

    formatter = editor_args.grid_control._formatters[formatter_name]
    formatter active_cell.row,
      active_cell.cell,
      editor_args.item[editor_args.column.field],
      editor_args.column,
      editor_args.item
