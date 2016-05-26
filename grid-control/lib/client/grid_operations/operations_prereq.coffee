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

  _opreqActivePath: (prereq) ->
    prereq = prepareOpreqArgs(prereq)

    if not @getCurrentPath()?
      prereq.no_active_path = "Select an item to perform this operation"

    return prereq

  _opreqActivePathIsCollectionItem: (prereq) ->
    prereq = prepareOpreqArgs(prereq)

    # If there's no active path - just return the active prereq message
    # note: @_opreqActivePath is reactive resource
    if not _.isEmpty(active_path_prereq = @_opreqActivePath())
      _.extend(prereq, active_path_prereq)
      return prereq

    if @_grid_data.getItemIsTyped(@getCurrentRow())
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

  _opreqActivePathLevelPermitted: (prereq) ->
    prereq = prepareOpreqArgs(prereq)

    # If there's no active path - just return the active prereq message
    # note: @_opreqActivePath is reactive resource
    if not _.isEmpty(active_path_prereq = @_opreqActivePath())
      _.extend(prereq, active_path_prereq)
      return prereq

    if @_grid_data.getItemRelativeDepthPermitted(@getCurrentRow()) is -1
      prereq.active_path_level_not_permitted = ""

    return prereq

  _opreqActivePathParentLevelPermitted: (prereq) ->
    prereq = prepareOpreqArgs(prereq)

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

    # If there's no active path - just return the active prereq message
    if not _.isEmpty(active_path_prereq = @_opreqActivePath())
      _.extend(prereq, active_path_prereq)
      return prereq

    path_has_children = @_grid_data.filterAwareGetPathHasChildren(@getCurrentPath())
    if path_has_children == 1
      prereq.active_path_is_not_leaf = "Can't perform operation on an item with sub-items"

    if path_has_children == 2
      prereq.active_path_is_not_leaf_all_child_filtered = "Can't perform operation on an item with sub-items (has filtered children)"

    return prereq

  _opreqActivePathHasChildren: (prereq) ->
    prereq = prepareOpreqArgs(prereq)

    # If there's no active path - just return the active prereq message
    if not _.isEmpty(active_path_prereq = @_opreqActivePath())
      _.extend(prereq, active_path_prereq)
      return prereq

    path_has_children = @_grid_data.filterAwareGetPathHasChildren(@getCurrentPath())
    if path_has_children == 0
      prereq.active_path_has_no_children = "Can't perform this operation on an item with no sub-items"

    return prereq

  _opreqItemInLteLevelExistFollowingActiveInPermittedLevel: (prereq) ->
    prereq = prepareOpreqArgs(prereq)

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

    # If there's no active path - just return the active prereq message 
    if not _.isEmpty(active_path_prereq = @_opreqActivePath())
      _.extend(prereq, active_path_prereq)
      return prereq

    if @_grid_data.getItemNormalizedLevel(@getCurrentRow()) == 0
      prereq.top_level_item = "Can't perform this operation on first level items"

    return prereq

  _opreqActivePathPrevItemInGteLevel: (prereq) ->
    prereq = prepareOpreqArgs(prereq)

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
