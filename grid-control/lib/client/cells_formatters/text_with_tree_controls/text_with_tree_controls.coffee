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

    horizontal_padding = 4
    toggle_margin_left = -2

    toggle_width = 20
    level_indent = 15
    indentation_margin = (level_indent * level)
    toggle_indentation = horizontal_padding + toggle_margin_left + indentation_margin
    text_left_margin = indentation_margin + toggle_width + toggle_margin_left

    getRandomArbitrary = (min, max) -> Math.floor(Math.random() * (max - min) + min)

    index = null
    if item.seqId?
      index = item.seqId # Note we don't worry about reactivity -> seqId considered static.
    # else
    #   index = getRandomArbitrary(0, 10000)

    if not index?
      text_indent = 0
    else
      index_width_per_char = 8.2
      index_chars = Math.max(("" + index).length, 3) # minimum 3 to avoid too many indent differences
      index_width = Math.ceil(index_chars * index_width_per_char)
      index_horizontal_paddings = 6 * 2
      # Note: index label is box-sizing: content-box
      index_outer_width = index_width + index_horizontal_paddings
      index_margin_right = 3
      index_left = horizontal_padding + text_left_margin
      text_indent = 0 # index_outer_width + index_margin_right
      text_left_margin += index_outer_width + index_margin_right

    tree_control = """
      <div class="grid-formatter text-tree-control">
        <div class="grid-tree-control-toggle #{state}"
              style="left: #{toggle_indentation}px;"></div>
    """

    if index?
      tree_control += """
          <span class="label label-primary task-id"
                 style="left: #{index_left}px;
                        width: #{index_width}px;">
            #{index}
          </span>
      """

    tree_control += """
        <div class="grid-tree-control-text"
              style="margin-left: #{text_left_margin}px;
                      text-indent: #{text_indent}px;">#{value}</div>
      </div>
    """

    return tree_control