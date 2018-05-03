system_minimal_seq_id_space_on_grid = 3

getHeighestSeqId = ->
  # Returns seqId of the item with the highest sequence id under @collection
  # has, or undefined, if no item, or no item with sequence id exists.
  #
  # If APP.modules.project_page.curProj() exists, we limit the search
  # for the heighest sequence id to the current project only.
  #
  # Reactive resource
  #
  # Must be called with @ set to the current GridControl object.

  query = 
    seqId:
      $ne: null

  if (current_project_id = APP?.modules?.project_page?.curProj?())?
    # Not the most "pure" programming style to include a reference
    # to APP.modules.project_page.curProj() here, but the code doesn't
    # depend on it so that's a reasonable compromise with minimal
    # technical debt -Daniel
    query.project_id = current_project_id.id

  # Turned out to be too slow approach since minimongo with sort results in
  # 100s of ms computations
  # highest_seq_id_doc = @collection.findOne(query, {fields: {seqId: 1}, sort: {seqId: -1}})
  #
  # if not highest_seq_id_doc?
  #   return undefined
  #
  # return highest_seq_id_doc.seqId

  # This approach will work only in environments with JustDo enabled
  highest_seq_id = APP?.modules?.project_page?.curProj()?.getProjectDoc()?.lastTaskSeqId

  return highest_seq_id

getMinimalSeqIdSpace = ->
  # Returns the maximum between 3 and the the digits count of the item
  # returned from getHeighestSeqId.
  #
  # Reactive resource
  #
  # Must be called with @ set to the current GridControl object. 

  current_heighest_seq_id = getHeighestSeqId.call(@)

  if current_heighest_seq_id?
    current_heighest_seq_id_space = ("" + current_heighest_seq_id).length
  else
    current_heighest_seq_id_space = 0

  return Math.max(system_minimal_seq_id_space_on_grid, current_heighest_seq_id_space)

GridControl.installFormatter "textWithTreeControls",
  is_slick_grid_tree_control_formatter: true

  # gridControlInit: ->
  #   Defined in text_with_tree_controls-events.coffee

  # slick_grid_jquery_events:
  #   Defined in text_with_tree_controls-events.coffee

  slickGridColumnStateMaintainer: ->
    if not Tracker.active
      @logger.warn "slickGridColumnStateMaintainer: called outside of computation, skipping"

      return

    # Create a dependency and depend on it.
    dep = new Tracker.Dependency()
    dep.depend()

    highest_seqId_computation = null
    Tracker.nonreactive =>
      # Run in an isolated reactivity scope
      highest_seqId_computation = Tracker.autorun =>
        current_val = getMinimalSeqIdSpace.call(@) # Reactive
        cached_val = @getCurrentColumnData("minimal_seq_id_space") # non reactive

        if current_val != cached_val
          @setCurrentColumnData("minimal_seq_id_space", current_val)

          dep.changed()

        return

    Tracker.onInvalidate ->
      highest_seqId_computation.stop()

    return

  slick_grid: ->
    {row, cell, value, doc, self} = @getFriendlyArgs()

    level = @_grid_data.getItemLevel row
    expand_state = @_grid_data.getItemExpandState row

    state = ""
    if expand_state == 1
      state = "expand"
    else if expand_state == 0
      state = "collapse"

    if not value?
      value = ""

    value = self.xssGuard value

    if @options.allow_dynamic_row_height
      value = self.nl2br value

    current_left_pos = 0
    horizontal_padding = 3

    current_left_pos += horizontal_padding

    tree_control = ""

    if doc.priority?
      priority_width = 6 + 3 # (3 for right outline)

      priority_indentation = current_left_pos

      # We keep outside the grid-formatter container due to positioning needs (need it relative to the
      # .slick-dynamic-row-height .slick-cell for correct height)
      tree_control += """
        <div class="grid-tree-control-priority slick-prevent-edit"
             style="background-color: #{JustdoColorGradient.getColorRgbString(doc.priority or 0)}; left: #{priority_indentation}px;"></div>
      """

      current_left_pos += priority_width

    toggle_margin_left = 0
    toggle_width = 21
    toggle_margin_right = 0

    level_indent = 15
    indentation_margin = (level_indent * level)
    toggle_indentation = current_left_pos + toggle_margin_left + indentation_margin

    tree_control += """
      <div class="grid-formatter text-tree-control">
    """

    tree_control += """
      <div class="grid-tree-control-toggle slick-prevent-edit #{state}"
           style="left: #{toggle_indentation}px;"></div>
    """

    current_left_pos += indentation_margin + toggle_margin_left + toggle_width + toggle_margin_right

    # item icons
    tree_control += """
      <div class="grid-tree-control-item-icons">
    """

    if (description = doc.description)? and not _.isEmpty(description)
      tree_control += """
          <i class="fa fa-fw fa-align-left task-description slick-prevent-edit" title="Task description" aria-hidden="true"></i>
      """

    if (files = doc.files)?
      if files.length > 0
        tree_control += """
            <i class="fa fa-fw fa-paperclip task-files slick-prevent-edit" title="#{files.length} files" aria-hidden="true"></i>
        """

    tree_control += """
      </div>
    """

    index = null
    if doc.seqId? and not doc._omit_seqId_comp
      index = doc.seqId # Note we don't worry about reactivity -> seqId considered static.
    # else
    #   index = getRandomArbitrary(0, 10000) # getRandomArbitrary = (min, max) -> Math.floor(Math.random() * (max - min) + min)

    # We can't tell for sure whether slickGridColumnStateMaintainer is the
    # only one to affect the column cache, therefore, we don't rely on it
    # to set the value for us. We set the value ourself if we don't find one.
    if not (minimal_seq_id_space = @getCurrentColumnData("minimal_seq_id_space"))?
      minimal_seq_id_space = Tracker.nonreactive => getMinimalSeqIdSpace.call(@)
      @setCurrentColumnData("minimal_seq_id_space", minimal_seq_id_space)

    if index?
      index_width_per_char = 8.2

      # minimal_seq_id_space won't be accurate in environment without JustDo
      # projects, in such cases, we need to fallback to current cell seqId
      # length
      index_chars = Math.max(minimal_seq_id_space, ("" + index).length)   

      index_width = Math.ceil(index_chars * index_width_per_char)
      index_horizontal_paddings = 6 * 2
      # Note: index label is box-sizing: content-box
      index_outer_width = index_width + index_horizontal_paddings
      index_margin_right = 3
      index_left = current_left_pos

      tree_control += """
          <span class="label label-primary grid-tree-control-task-id slick-prevent-edit cell-handle"
                 style="left: #{index_left}px;
                        width: #{index_width}px;">
            #{index}
          </span>
      """

      current_left_pos += index_outer_width + index_margin_right

    # shortcuts
    owner_id = pending_owner_id = null
    if doc.owner_id? and not doc._omit_owner_control
      owner_id = doc.owner_id # For reactivity, make sure to specify owner_id and pending_owner_id as
                               # dependencies
      pending_owner_id = doc.pending_owner_id

    if owner_id?
      doc = @_grid_data.extendObjForeignKeys doc,
        in_place: false
        foreign_keys: ["owner_id"]

      owner_doc = doc.owner

      if owner_doc?
        owner_display_name = owner_doc?.profile?.first_name + " " + owner_doc?.profile?.last_name

      owner_id_width = 28
      owner_id_margin_right = 0
      owner_id_left = 1 + current_left_pos
      current_left_pos += owner_id_width + owner_id_margin_right

      title = owner_display_name
      if pending_owner_id?
        doc = @_grid_data.extendObjForeignKeys doc,
          in_place: false
          foreign_keys: ["pending_owner_id"]

        pending_owner_doc = doc.pending_owner

        if pending_owner_doc?
          pending_owner_display_name = pending_owner_doc?.profile?.first_name + " " + pending_owner_doc?.profile?.last_name

        title += " &rarr; " + pending_owner_display_name


      tree_control += """
        <div class="grid-tree-control-user slick-prevent-edit"
             title="#{title}"
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
          <div class="transfer-owner #{transfer_type} slick-prevent-edit"></div>
        """


      tree_control += """
        </div>
      """

    text_left_margin = current_left_pos

    tree_control += """
        <div class="grid-tree-control-text"
              style="margin-left: #{text_left_margin}px;">#{value}</div>
    """

    tree_control += """
      </div>
    """

    # We keep outside the grid-formatter container due to positioning needs (need it relative to the
    # .slick-dynamic-row-height .slick-cell for correct height)
    tree_control += """
      <div class="grid-tree-control-activation-area slick-prevent-edit"
               style="width: #{toggle_indentation}px;"></div>
    """

    return tree_control

  print: (doc, field, path) ->
    return @defaultPrintFormatter()
