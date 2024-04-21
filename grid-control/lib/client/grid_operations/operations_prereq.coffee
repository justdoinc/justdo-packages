prepareOpreqArgs = JustdoHelpers.prepareOpreqArgs

_.extend GridControl.prototype,
  # The following methods used to generate a prerequisites object,
  # that is, an object that should be used to determine whether
  # operation's prerequisites are fulfilled before its execution.

  # These prerequisites generators receive an object as a parameter
  # and add to this object *only* the unfulfilled prerequisites.
  # The key is the prereq id the value is a human readable message to
  # be presented to the user when prereq isn't fulfilled.
  # (In case custom messages are needed, developers can disregard the
  #  message and use a custom one based on the prereq key instead).

  # The generators will make it easy to define operation prerequisites
  # Example:
  # prereq = @_opreqActivePath(@_opreqUnlocked({}))
  #
  # prereq will be an empty obj if operations lock is released and there's
  # an active path in the grid.
  # otherwise it won't be empty and its properties will list the issues.

  # Notes:
  # * The following should address only the common prerequisites, special
  # ones should be defined.
  # * All prereq generators should be reactive resources.
  # * As a standard prefix all prereq generators with _opreq (stands for
  # operation requires).

  _opreqGridReady: (prereq) ->
    prereq = prepareOpreqArgs(prereq)

    if not @ready.get()
      prereq.grid_not_ready = "Waiting for grid to become ready"

    return prereq

  _opreqUnlocked: (prereq) ->
    prereq = prepareOpreqArgs(prereq)

    if @_operations_lock.get()
      prereq.ops_locked = "Waiting for operations to complete"

    return prereq

  _opreqSingleSelectModeOrConsecutiveMultiSelect: (prereq) ->
    prereq = prepareOpreqArgs(prereq)

    if not @isMultiSelectMode() or @isMultiSelectConsecutiveSelect()
      return prereq

    prereq.multi_select_non_consecutive_not_supported = "This operation is allowed only when a consecutive items are selected"

    return prereq

  _opreqNotMultiSelectMode: (prereq) ->
    prereq = prepareOpreqArgs(prereq)

    if @isMultiSelectMode()
      prereq.multi_select_mode_not_supported = "This operation can't be performed when more than one item is selected"

    return prereq

  _opreqActivePath: (prereq) ->
    prereq = prepareOpreqArgs(prereq)

    if not @getCurrentPath()?
      prereq.no_active_path = "Select an item to perform this operation"

    return prereq

  _opreqActivePathIsCollectionItem: (prereq) ->
    prereq = prepareOpreqArgs(prereq)

    if @isMultiSelectMode()
      #
      # Deal first with the case of multi-select
      #
      for path in @getFilterPassingMultiSelectedPathsArray()
        path_row = @_grid_data.getPathGridTreeIndex(path)
        
        if not @_grid_data.getItemIsCollectionItem(path_row)
          prereq.selected_isnt_collection_item = ""

          break

      return prereq

    # If there's no active path - just return the active prereq message
    # note: @_opreqActivePath is reactive resource
    if not _.isEmpty(active_path_prereq = @_opreqActivePath())
      _.extend(prereq, active_path_prereq)
      return prereq

    if not @_grid_data.getItemIsCollectionItem(@getCurrentRow())
      prereq.active_path_isnt_collection_item = ""

    return prereq

  _opreqActivePathChildrenLevelPermitted: (prereq) ->
    prereq = prepareOpreqArgs(prereq)

    # If there's no active path - just return the active prereq message
    # note: @_opreqActivePath is reactive resource
    if not _.isEmpty(active_path_prereq = @_opreqActivePath())
      _.extend(prereq, active_path_prereq)
      return prereq

    if @_grid_data.getItemRelativeDepthPermitted(@getCurrentRow(), 1) is -1
      prereq.active_path_children_level_not_permitted = ""

    return prereq

  _opreqActivePathLevelPermitted: (prereq, operation_id) ->
    prereq = prepareOpreqArgs(prereq)

    if @isMultiSelectMode()
      #
      # Deal first with the case of multi-select
      #
      for path in @getFilterPassingMultiSelectedPathsArray()
        path_row = @_grid_data.getPathGridTreeIndex(path)
        
        if @_grid_data.getItemRelativeDepthPermitted(path_row) is -1
          if operation_id is "remove"

            grid_data = @_grid_data
            section = grid_data.getItemSection(path_row)

            if (removeSpecialCase = section.options?.permitted_depth_removeSpecialCase)? and
               removeSpecialCase.call(@, path_row)
                  continue

          prereq.selected_path_level_not_permitted = ""

          break

      return prereq

    # If there's no active path - just return the active prereq message
    # note: @_opreqActivePath is reactive resource
    if not _.isEmpty(active_path_prereq = @_opreqActivePath())
      _.extend(prereq, active_path_prereq)
      return prereq

    if @_grid_data.getItemRelativeDepthPermitted(@getCurrentRow()) is -1
      prereq.active_path_level_not_permitted = ""

    if operation_id is "remove"
      if "active_path_level_not_permitted" of prereq
        current_row = @getCurrentRow()

        grid_data = @_grid_data
        section = grid_data.getItemSection(current_row)

        if (removeSpecialCase = section.options?.permitted_depth_removeSpecialCase)? and
           removeSpecialCase.call(@, current_row)
              delete prereq.active_path_level_not_permitted

    return prereq

  _opreqActivePathParentLevelPermitted: (prereq) ->
    prereq = prepareOpreqArgs(prereq)

    if @isMultiSelectMode()
      #
      # Deal first with the case of multi-select
      #

      # If the selection isn't consecutive - this prereq isn't supported
      if not _.isEmpty(consecutive_prereq = @_opreqSingleSelectModeOrConsecutiveMultiSelect())
        _.extend(prereq, consecutive_prereq)
        return prereq

      first_selected_item_path = @getFilterPassingMultiSelectedPathsArray()[0]
      first_selected_item_path_row = @_grid_data.getPathGridTreeIndex(first_selected_item_path)
      
      if @_grid_data.getItemRelativeDepthPermitted(first_selected_item_path_row, -1) is -1
        prereq.active_path_parent_level_not_permitted = ""

      return prereq

    # If there's no active path - just return the active prereq message
    # note: @_opreqActivePath is reactive resource
    if not _.isEmpty(active_path_prereq = @_opreqActivePath())
      _.extend(prereq, active_path_prereq)
      return prereq

    if @_grid_data.getItemRelativeDepthPermitted(@getCurrentRow(), -1) is -1
      prereq.active_path_parent_level_not_permitted = ""

    return prereq

  _opreqActivePathPrevItemLevelPermitted: (prereq) ->
    prereq = prepareOpreqArgs(prereq)

    if @isMultiSelectMode()
      #
      # Deal first with the case of multi-select
      #

      # If the selection isn't consecutive - this prereq isn't supported
      if not _.isEmpty(consecutive_prereq = @_opreqSingleSelectModeOrConsecutiveMultiSelect())
        _.extend(prereq, consecutive_prereq)
        return prereq

      boundaries = @getMultiSelectConsecutiveSelectBoundaries()

      if not (previous_path = boundaries[0])? # There's no item after the current selection
        prereq.active_path_prev_item_level_not_permitted = "No item before the selected items"

        return prereq

      previous_path_row = @_grid_data.getPathGridTreeIndex(previous_path)

      if not previous_path_row? or @_grid_data.getItemRelativeDepthPermitted(previous_path_row) == -1
        prereq.active_path_prev_item_level_not_permitted = "No item before the selected items in permitted lower level"

      return prereq

    # If there's no prev path - just return the active_path_item_isnt_first_prereq message
    # note @_opreqActiveItemIsntSectionFirstItem also takes care of making sure there's
    # an active path
    if not _.isEmpty(active_path_item_isnt_first_prereq = @_opreqActiveItemIsntSectionFirstItem())
      _.extend(prereq, active_path_item_isnt_first_prereq)
      return prereq

    previous_item_index = @_grid_data.filterAwareGetPreviousItem(@getCurrentRow())

    if @_grid_data.getItemRelativeDepthPermitted(previous_item_index) == -1
      prereq.active_path_prev_item_level_not_permitted = ""

    return prereq

  _opreqActivePathIsLeaf: (prereq) ->
    prereq = prepareOpreqArgs(prereq)

    if @isMultiSelectMode()
      #
      # Deal first with the case of multi-select
      #

      for path in @getFilterPassingMultiSelectedPathsArray()
        path_has_children = @_grid_data.filterAwareGetPathHasChildren(path)

        if path_has_children == 0
          continue

        item_id = GridData.helpers.getPathItemId(path)
        item = @collection.findOne(item_id, {fields: {title: 1, seqId: 1}})

        if path_has_children == 1
          prereq.selected_path_is_not_leaf = "Can't perform operation. The following task has a Child Task: #{JustdoHelpers.taskCommonName(item, 50)}"

          break

        if path_has_children == 2
          prereq.selected_path_is_not_leaf_all_child_filtered = "Can't perform operation. The following task has a filtered Child Task: #{JustdoHelpers.taskCommonName(item, 50)}"

          break

        if path_has_children == 3
          prereq.selected_path_is_not_leaf_is_archived = "Can't perform operation. The following task is archived and has children under it: #{JustdoHelpers.taskCommonName(item, 50)}"

          break

      return prereq

    # If there's no active path - just return the active prereq message
    if not _.isEmpty(active_path_prereq = @_opreqActivePath())
      _.extend(prereq, active_path_prereq)
      return prereq

    path_has_children = @_grid_data.filterAwareGetPathHasChildren(@getCurrentPath())
    if path_has_children == 1
      prereq.active_path_is_not_leaf = "Can't perform operation on an item with child tasks"

    if path_has_children == 2
      prereq.active_path_is_not_leaf_all_child_filtered = "Can't perform operation on an item with child tasks (has filtered children)"

    if path_has_children == 3
      prereq.active_path_is_not_leaf_is_archived = "Can't perform operation on an item with child tasks (archived task with children)"

    return prereq

  _opreqActivePathIsLeafOrHaveMultipleParents: (prereq) ->
    prereq = prepareOpreqArgs(prereq)

    if @isMultiSelectMode()
      #
      # Deal first with the case of multi-select
      #

      for path in @getFilterPassingMultiSelectedPathsArray()
        item_id = GridData.helpers.getPathItemId(path)

        if @_grid_data.getAllCollectionItemIdPaths(item_id, false, true)?.length > 1 # true is to allow consideration of unreachable tasks when deciding if has multi-parents
          continue

        path_has_children = @_grid_data.filterAwareGetPathHasChildren(path)

        if path_has_children == 0
          continue

        item = @collection.findOne(item_id, {fields: {title: 1, seqId: 1}})

        if path_has_children == 1
          prereq.selected_path_is_not_leaf = "Can't perform operation. The following task has a Child Task: #{JustdoHelpers.taskCommonName(item, 50)}"

          break

        if path_has_children == 2
          prereq.selected_path_is_not_leaf_all_child_filtered = "Can't perform operation. The following task has a filtered Child Task: #{JustdoHelpers.taskCommonName(item, 50)}"

          break

        if path_has_children == 3
          prereq.selected_path_is_not_leaf_is_archived = "Can't perform operation. The following task is archived and has children under it: #{JustdoHelpers.taskCommonName(item, 50)}"

          break

      return prereq

    # If there's no active path - just return the active prereq message
    if not _.isEmpty(active_path_prereq = @_opreqActivePath())
      _.extend(prereq, active_path_prereq)
      return prereq

    # If the current path is under only one parent and it is leaf, block the opreation
    current_item_id = GridData.helpers.getPathItemId(@getCurrentPath())
    if @_grid_data.getAllCollectionItemIdPaths(current_item_id, false, true)?.length == 1 and # true is to allow consideration of unreachable tasks when deciding if has multi-parents
        not _.isEmpty(active_path_prereq = @_opreqActivePathIsLeaf())
      _.extend(prereq, active_path_prereq)
      return prereq

    return prereq

  _opreqActivePathHasChildren: (prereq) ->
    prereq = prepareOpreqArgs(prereq)

    # If there's no active path - just return the active prereq message
    if not _.isEmpty(active_path_prereq = @_opreqActivePath())
      _.extend(prereq, active_path_prereq)
      return prereq

    path_has_children = @_grid_data.filterAwareGetPathHasChildren(@getCurrentPath())
    if path_has_children == 0
      prereq.active_path_has_no_children = "Can't perform this operation on an item with no child tasks"

    return prereq

  _opreqItemInLteLevelExistFollowingActiveInPermittedLevel: (prereq) ->
    prereq = prepareOpreqArgs(prereq)

    if @isMultiSelectMode()
      #
      # Deal first with the case of multi-select
      #

      # If the selection isn't consecutive - this prereq isn't supported
      if not _.isEmpty(consecutive_prereq = @_opreqSingleSelectModeOrConsecutiveMultiSelect())
        _.extend(prereq, consecutive_prereq)
        return prereq

      boundaries = @getMultiSelectConsecutiveSelectBoundaries()

      if not (following_path = boundaries[1])? # There's no item after the current selection
        prereq.no_permitted_lte_level_path_follows_active = "No item follows the selected items"

        return prereq

      following_path_row = @_grid_data.getPathGridTreeIndex(following_path)

      if not following_path_row? or @_grid_data.getItemRelativeDepthPermitted(following_path_row) == -1
        prereq.no_permitted_lte_level_path_follows_active = "No item follows the selected items in permitted lower level"

      return prereq

    # If there's no active path - just return the active prereq message 
    if not _.isEmpty(active_path_prereq = @_opreqActivePath())
      _.extend(prereq, active_path_prereq)
      return prereq

    next_lte_level_index = @_grid_data.filterAwareGetNextLteLevelItem(@getCurrentRow())
    if not next_lte_level_index? or @_grid_data.getItemRelativeDepthPermitted(next_lte_level_index) == -1
      prereq.no_permitted_lte_level_path_follows_active = "No item follows the item in permitted lower level"

    return prereq

  _opreqActiveItemIsntSectionFirstItem: (prereq) ->
    prereq = prepareOpreqArgs(prereq)

    if @isMultiSelectMode()
      #
      # Deal first with the case of multi-select
      #

      # If the selection isn't consecutive - this prereq isn't supported
      if not _.isEmpty(consecutive_prereq = @_opreqSingleSelectModeOrConsecutiveMultiSelect())
        _.extend(prereq, consecutive_prereq)
        return prereq

      first_selected_item_path = @getFilterPassingMultiSelectedPathsArray()[0]

      previous_path = @_grid_data.filterAwareGetPreviousPath(first_selected_item_path)

      if not previous_path? or previous_path of @_grid_data.section_path_to_section # if no previous path, or if prev path is the section item
        prereq.first_selected_item_is_first = "Can't perform this operation when the first item is selected"

      return prereq

    # If there's no active path - just return the active prereq message 
    if not _.isEmpty(active_path_prereq = @_opreqActivePath())
      _.extend(prereq, active_path_prereq)
      return prereq

    previous_path = @_grid_data.filterAwareGetPreviousPath(@getCurrentPath())
    if not previous_path? or previous_path of @_grid_data.section_path_to_section # if no previous path, or if prev path is the section item
      prereq.active_item_is_first = "Can't perform this operation on the first item"

    return prereq

  _opreqActiveItemIsntSectionTopLevel: (prereq) ->
    prereq = prepareOpreqArgs(prereq)

    if @isMultiSelectMode()
      #
      # Deal first with the case of multi-select
      #

      # If the selection isn't consecutive - this prereq isn't supported
      if not _.isEmpty(consecutive_prereq = @_opreqSingleSelectModeOrConsecutiveMultiSelect())
        _.extend(prereq, consecutive_prereq)
        return prereq

      first_selected_item_path = @getFilterPassingMultiSelectedPathsArray()[0]

      first_selected_item_path_row = @_grid_data.getPathGridTreeIndex(first_selected_item_path)

      if @_grid_data.getItemNormalizedLevel(first_selected_item_path_row) == 0
        prereq.top_level_item = "Can't perform this operation on first level items"

      return prereq

    # If there's no active path - just return the active prereq message 
    if not _.isEmpty(active_path_prereq = @_opreqActivePath())
      _.extend(prereq, active_path_prereq)
      return prereq

    if @_grid_data.getItemNormalizedLevel(@getCurrentRow()) == 0
      prereq.top_level_item = "Can't perform this operation on first level items"

    return prereq

  _opreqActivePathPrevItemInGteLevel: (prereq) ->
    prereq = prepareOpreqArgs(prereq)

    if @isMultiSelectMode()
      #
      # Deal first with the case of multi-select
      #

      # If the selection isn't consecutive - this prereq isn't supported
      if not _.isEmpty(consecutive_prereq = @_opreqSingleSelectModeOrConsecutiveMultiSelect())
        _.extend(prereq, consecutive_prereq)
        return prereq

      first_selected_item_path = @getFilterPassingMultiSelectedPathsArray()[0]
      first_selected_item_path_level = GridData.helpers.getPathLevel first_selected_item_path
      prev_path_level = GridData.helpers.getPathLevel @_grid_data.filterAwareGetPreviousPath(first_selected_item_path)

      if first_selected_item_path_level > prev_path_level
        prereq.prev_item_not_deeper = "Can't perform this operation when previous item isn't in a deeper level"

      return prereq

    # If there's no prev path - just return the active_path_item_isnt_first_prereq message
    # note @_opreqActiveItemIsntSectionFirstItem also takes care of making sure there's
    # an active path
    if not _.isEmpty(active_path_item_isnt_first_prereq = @_opreqActiveItemIsntSectionFirstItem())
      _.extend(prereq, active_path_item_isnt_first_prereq)
      return prereq

    current_path = @getCurrentPath()
    curr_path_level = GridData.helpers.getPathLevel current_path
    prev_path_level = GridData.helpers.getPathLevel @_grid_data.filterAwareGetPreviousPath(current_path)

    if curr_path_level > prev_path_level
      prereq.prev_item_not_deeper = "Can't perform this operation when previous item isn't in a deeper level"

    return prereq
  
  _opreqActivePathIsntArchived: (prereq) -> # We respect ignored archived for the current view. We regard them as non-archived.
    prereq = prepareOpreqArgs(prereq)

    current_path = @getCurrentPath()

    if current_path?
      # The following is required to become reactive to changes in the archived field
      @getCurrentPathObj({archived: 1})

      if @_grid_data.isPathArchived(current_path)
        _.extend(prereq,
          sub_task_reachable: "Can't perform this operation on an archived task"
        )

    return prereq
