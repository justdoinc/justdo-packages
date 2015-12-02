helpers = PACK.FormattersHelpers

_.extend PACK.Formatters,
  textWithTreeControls: (row, cell, value, columnDef, item) ->
    level = @_grid_data.getItemLevel row
    has_childs = @_grid_data.getItemHasChild row
    expand = @_grid_data.getItemIsExpand row

    state = ""
    if has_childs
      if expand
        state = "expand"
      else
        state = "collapse"

    if not value?
      value = ""

    value = helpers.xssGuard value

    if @options.allow_dynamic_row_height
      value = helpers.nl2br value

    horizontal_padding = 2
    toggle_width = 20
    level_indent = 15
    toggle_indentation = horizontal_padding + (level_indent * level)
    text_indentation = toggle_indentation + toggle_width
    # we need to horizonal padding only for the left property that ignore it (position: absolute)
    text_indentation -= horizontal_padding

    tree_control = """
      <div class="grid-formatter text-tree-control">
        <div class="grid-tree-control-toggle #{state}"
              style="left: #{toggle_indentation}px;"></div>
        <div class="grid-tree-control-text"
              style="margin-left: #{text_indentation}px;">#{value}</div>
      </div>
    """

    return tree_control