getSpacer = (level) -> "<span class='grid-tree-control-spacer' style='width: #{15 * level}px'></span>"

_.extend PACK.Formatters,
  textWithTreeControls: (row, cell, value, columnDef, item) ->
    output = PACK.Formatters.defaultFormatter(row, cell, value, columnDef, item)

    level = @_grid_data.getItemLevel(row)
    has_childs = @_grid_data.getItemHasChild row
    expand = @_grid_data.getItemIsExpand row

    state = ""
    if has_childs
      if expand
        state = "expand"
      else
        state = "collapse"
    tree_control = "<span class='grid-tree-control-toggle #{state}'></span>"

    getSpacer(level) + tree_control + output