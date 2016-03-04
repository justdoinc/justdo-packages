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

    if not @current_path.get()?
      prereq.no_active_path = "Select an item to perform this operation"

    return prereq

  _opreqActivePathIsLeaf: (prereq) ->
    prereq = prepareOpreqArgs(prereq)

    active_path_prereq = @_opreqActivePath()

    # If there's no active path - just return the active prereq message
    if not _.isEmpty active_path_prereq
      _.extend(prereq, active_path_prereq)
      return prereq

    path_has_children = @_grid_data.pathHasChildren(@current_path.get())
    if path_has_children == 1
      prereq.active_path_is_not_leaf = "Can't perform operation on an item with sub-items"

    if path_has_children == 2
      prereq.active_path_is_not_leaf_all_child_filtered = "Can't perform operation on an item with sub-items (has filtered children)"

    return prereq

  _opreqActivePathHasChildren: (prereq) ->
    prereq = prepareOpreqArgs(prereq)

    active_path_prereq = @_opreqActivePath()

    # If there's no active path - just return the active prereq message
    if not _.isEmpty active_path_prereq
      _.extend(prereq, active_path_prereq)
      return prereq

    path_has_children = @_grid_data.pathHasChildren(@current_path.get())
    if path_has_children == 0
      prereq.active_path_has_no_children = "Can't perform this operation on an item with no sub-items"

    return prereq

  _opreqActiveItemInLteLevelExistFollwingActive: (prereq) ->
    prereq = prepareOpreqArgs(prereq)

    active_path_prereq = @_opreqActivePath()

    # If there's no active path - just return the active prereq message 
    if not _.isEmpty active_path_prereq
      _.extend(prereq, active_path_prereq)
      return prereq

    if not @_grid_data.getNextLteLevelPath(@current_path.get())?
      prereq.no_lte_level_path_follows_active = "No item follows the item in lower level"

    return prereq

  _opreqActiveItemIsntFirst: (prereq) ->
    prereq = prepareOpreqArgs(prereq)

    active_path_prereq = @_opreqActivePath()

    # If there's no active path - just return the active prereq message 
    if not _.isEmpty active_path_prereq
      _.extend(prereq, active_path_prereq)
      return prereq

    if not @_grid_data.getPreviousPath(@current_path.get())?
      prereq.active_item_is_first = "Can't perform this operation on the first item"

    return prereq

  _opreqActiveItemIsntUnderRoot: (prereq) ->
    prereq = prepareOpreqArgs(prereq)

    active_path_prereq = @_opreqActivePath()

    # If there's no active path - just return the active prereq message 
    if not _.isEmpty active_path_prereq
      _.extend(prereq, active_path_prereq)
      return prereq

    parent_path = GridData.helpers.getParentPath(@current_path.get())

    if parent_path == "/"
      prereq.first_level_item = "Can't perform this operation on first level items"

    return prereq

  _opreqActiveItemPrevSiblingInGteLevel: (prereq) ->
    prereq = prepareOpreqArgs(prereq)

    active_path_item_isnt_first_prereq = @_opreqActiveItemIsntFirst()
    # If there's no prev path - just return the active_path_item_isnt_first_prereq message
    # note @_opreqActiveItemIsntFirst also takes care of making sure there's
    # an active path
    if not _.isEmpty active_path_item_isnt_first_prereq
      _.extend(prereq, active_path_item_isnt_first_prereq)
      return prereq

    current_path = @current_path.get()
    curr_path_level = @_grid_data.getPathLevel current_path
    prev_path_level = @_grid_data.getPathLevel @_grid_data.getPreviousPath(current_path)

    if curr_path_level > prev_path_level
      prereq.prev_item_not_deeper = "Can't perform this operation when previous item isn't in a deeper level"

    return prereq
