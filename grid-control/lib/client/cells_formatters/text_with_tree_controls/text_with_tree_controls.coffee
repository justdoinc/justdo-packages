helpers = PACK.FormattersHelpers

_.extend PACK.Formatters,
  textWithTreeControls: (row, cell, value, columnDef, item) ->
    level = @_grid_data.getItemLevel row
    # has_childs note: we print the toggle button for filtered item (result ==
    # 2) being hidden in the css level
    has_childs = @_grid_data.getItemHasChildren(row) > 0
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

    horizontal_padding = 5

    toggle_margin_left = -5
    toggle_width = 21
    toggle_margin_right = 0

    level_indent = 15
    indentation_margin = (level_indent * level)
    toggle_indentation = horizontal_padding + toggle_margin_left + indentation_margin
    text_left_margin = indentation_margin + toggle_margin_left + toggle_width + toggle_margin_right

    tree_control = ""

    tree_control += """
      <div class="grid-tree-control-toggle slick-prevent-edit #{state}"
           style="left: #{toggle_indentation}px;"></div>
    """

    index = null
    if item.seqId?
      index = item.seqId # Note we don't worry about reactivity -> seqId considered static.
    # else
    #   index = getRandomArbitrary(0, 10000) # getRandomArbitrary = (min, max) -> Math.floor(Math.random() * (max - min) + min)

    if index?
      index_width_per_char = 8.2
      index_chars = Math.max(("" + index).length, 3) # minimum 3 to avoid too many indent differences
      index_width = Math.ceil(index_chars * index_width_per_char)
      index_horizontal_paddings = 6 * 2
      # Note: index label is box-sizing: content-box
      index_outer_width = index_width + index_horizontal_paddings
      index_margin_right = 3
      index_left = horizontal_padding + text_left_margin
      text_left_margin += index_outer_width + index_margin_right

      tree_control += """
          <span class="label label-primary grid-tree-control-task-id slick-prevent-edit cell-handle"
                 style="left: #{index_left}px;
                        width: #{index_width}px;">
            #{index}
          </span>
      """

    # shortcuts
    owner_id = pending_owner_id = null
    if item.owner_id?
      owner_id = item.owner_id # For reactivity, make sure to specify owner_id and pending_owner_id as
                               # dependencies
      pending_owner_id = item.pending_owner_id

    if owner_id?
      item = @_grid_data.extendItemForeignKeys item,
        in_place: false
        foreign_keys: ["owner_id"]

      owner_doc = item.owner

      if owner_doc?
        owner_display_name = owner_doc?.profile?.first_name + " " + owner_doc?.profile?.last_name

      owner_id_width = 28
      owner_id_margin_right = 2
      owner_id_left = horizontal_padding - 1 + text_left_margin
      text_left_margin += owner_id_width + owner_id_margin_right

      tree_control += """
        <div class="grid-tree-control-user slick-prevent-edit"
             title="#{owner_display_name}"
             style="left: #{owner_id_left}px;
                    width: #{owner_id_width}px;
                    height: #{owner_id_width}px;">
          <img src="#{JustdoAvatar.showUserAvatarOrFallback(owner_doc)}"
               class="grid-tree-control-user-img slick-prevent-edit"
               alt="#{owner_display_name}"
               style="left: #{owner_id_left}px;
                      width: #{owner_id_width}px;
                      height: #{owner_id_width}px;">
      """

      if pending_owner_id?
        transfer_type = "transfer-non-related"
        if Meteor.userId() == pending_owner_id
          transfer_type = "transfer-to-me"
        else if Meteor.userId() == owner_id
          transfer_type = "transfer-from-me"

        tree_control += """
          <div class="transfer-owner #{transfer_type}"></div>
        """

      tree_control += """
        </div>
      """

    tree_control += """
        <div class="grid-tree-control-text"
              style="margin-left: #{text_left_margin}px;">#{value}</div>
    """

    tree_control = """
      <div class="grid-formatter text-tree-control">
        <div class="grid-tree-control-activation-area slick-prevent-edit"
                 style="width: #{text_left_margin + horizontal_padding}px;"></div>
        #{tree_control}
      </div>
    """

    return tree_control
