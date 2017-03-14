numSort = (a, b) -> a - b # Be careful from unintended consequence of changing as grid-data is {bare: true} and has same func

GridDataSectionManager = (grid_data_obj, section_root, section_obj, options) ->
  EventEmitter.call this

  @grid_data = grid_data_obj
  @section_root = section_root
  @section_root_no_trailing_slash = @section_root.replace(/\/$/, "")
  @section_obj = section_obj

  @state_vars = {}

  return @

Util.inherits GridDataSectionManager, EventEmitter

_.extend GridDataSectionManager.prototype,
  #
  # _destroy
  #
  _destroy: ->
    # Called when it's time for the section manager to relase the
    # resources it is using

    @emit "destroy"

    # inheritors must implement @destroy()
    @destroy()

    @emit "destroyed"

    return

  relPath: (absolute_path) ->
    absolute_path.substr(@section_root.length - 1) # -1 is to leave first /

  absPath: (relative_path) ->
    @section_root_no_trailing_slash + relative_path

  #
  # _inExpandedPaths
  #
  _inExpandedPaths: (relative_path) ->
    # check if relative_path in @_expanded_paths
    #
    # IMPORTANT: this alone doesn't mean whether the path is presented (all ancestors expanded)
    # nor whether it really expanded (if it has no children it has no meaning)
    #
    # not filters aware
    absolute_path = @absPath(relative_path)

    if absolute_path == "/" # root always expanded
      return 1

    return if absolute_path of @grid_data._expanded_paths then 1 else 0

  #
  # isPathExist
  #
  _isPathExist: (relative_path) ->
    # Should be implemented by inheritors
    #
    # Can assume relative_path is not "/"
    return false

  isPathExist: (absolute_path) ->
    # gets an absolute absolute_path makes it section relative and
    # pass to isPathExist
    #
    # IMPORTANT: We assume that absolute_path is under this section!
    relative_path = @relPath(absolute_path)

    if relative_path == "/"
      # Path points to the Section Item
      return true

    return @_isPathExist(relative_path)

  _hasPassingFilterDescendants: (absolute_path, options) ->
    # options are the options we will use when calling @_each
    # _hasPassingFilterDescendants will use the following defaults options:
    # * expand_only: false
    # * (remember, that filtered_tree: false, since this option isn't implemented
    #    in this level but in grid_data's _each() level)
    #
    # IMPORTANT:
    # * We assume that absolute_path is under this section!
    # * Unless you know for sure @grid_data._each() optimizations won't help. Don't use
    #   this method when @grid_tree and @_grid_tree_filter_state are ready,
    #   always use grid_data's @_each that has optimizations this method doesn't
    #   have.

    #
    # Prepare args
    #
    relative_path = @relPath(absolute_path)

    # We don't use _.extend here on purpose, _hasPassingFilterDescendants used
    # heavily in loops, and _.extend is too expensive for that
    if not options?
      options = {}

    if not options.expand_only?
      options.expand_only = false

    #
    # look for descendants
    #
    pass = false

    @_each relative_path, options, (section, item_type, item_obj, path, expand_state) =>
      if @grid_data.pathPassFilter path
        pass = true

        return -2 # Found, stop the _each by returning -2

    return pass

  #
  # each
  #
  _each: (relative_path, options, iteratee) ->
    # SHOULD BE IMPLEMENTED BY INHERITORS

    # GridData _each should always be used as a proxy to sections _each
    # as it add optimizations and takes filters into account when necessary

    # _each(relative_path, options, iteratee)
    #
    # Traverse the section items in the given path
    #
    # options:
    # * expand_only (default: true): if true the method will regard non-expanded items as
    # leaves.
    #
    # It is safe to assume that options is an object and that it includes all default options
    # (prepared by each())
    #
    # Call iteratee for every item as follow:
    #
    #   iteratee(section, item_type, item_obj, path, expand_state)
    #
    #   section:      path's section object
    #   item_type:    null if item_obj is a document of grid_data's
    #                 @collection. Otherwise will hold a string with
    #                 the item type.
    #   item_obj:     the item object
    #   path:         the item's path under the root tree
    #   expand_state: undefined if expand_only option is false
    #                 -1 if item has no children, 0 if collapsed, 1 if expanded
    #
    #   if iteratee returns:
    #     -1: traversing won't attempt to step into item's under the
    #     current item
    #     -2: traversing will stop immediately
    #
    # Will return false if forced to stop by iteratee, true if travesing completed
    #
    return true

  #
  # hasChildren
  #
  hasChildren: (relative_path) ->
    # Returns true if section has any children, even if hidden due to collapse
    # or filter not filters aware

    # IMPORTANT! for items in the presented tree, use the @grid_tree expand state
    # detail to avoid redundant calculation

    has_children = false

    @_each relative_path, {expand_only: false}, (section, item_type, item_obj, relative_path) ->
      has_children = true

      return -2 # no need to continue

    return has_children

  #
  # expandState
  #
  expandState: (relative_path) ->
    # Returns:
    # -1 if relative_path has no children
    # 0 if relative_path has children and is collapsed
    # 1 if relative_path has children and is expanded

    # IMPORTANT expand state 

    # IMPORTANT! for items in the presented tree, use the @grid_tree expand state
    # detail to avoid redundant calculation

    # not filters aware

    if not @hasChildren(relative_path)
      return -1

    return @_inExpandedPaths(relative_path)

  #
  # isDepthPermitted
  #
  isDepthPermitted: (normalized_level) ->
    # Return:
    #  -1 if operations on normalized_level aren't permitted
    #   0 if operations on normalized_level are permitted and can affect any depth of the section
    #   1 if operations on normalized_level are permitted and can affect only non-section's root level items (normalized level > 0).
    #   2 XXX NOT IMPLEMENTED YET if operations on normalized_level are permitted and can affect only non-section's root level items under the same top-level parent subtree.

    permitted_depth = @section_obj.options.permitted_depth

    if normalized_level == -1
      # Section items are never movable
      return -1

    if permitted_depth in [-1, 0]
      # In these permitted_depth, normalized_level has no effect
      return permitted_depth

    # permitted_depth > 0, 0 level items not movable 
    if normalized_level == 0
      return -1

    return permitted_depth

  #
  # @collection tree traversing
  #
  _collectionItemHasChildren: (item_id) ->
    # Return true if item_id has children
    #
    (item_id of @grid_data.tree_structure) and not _.isEmpty(@grid_data.tree_structure[item_id])

  _naturalCollectionTreeTraversing: (item_id, target_path, options, iteratee, _derived_call) ->
    # _naturalCollectionTreeTraversing(root_id, item_id, target_path, options, iteratee)
    #
    # Traverse @collection items
    #
    # options:
    #
    # * expand_only (default: true): if true the method will regard non-expanded items as
    # leaves.
    #
    # iteratee arguments will be affected by the options:
    # if expand_only is true:
    #   iteratee(item_id, item_path, expand_state)
    # else
    #   iteratee(item_id, item_path)
    #
    # if iteratee returns:
    #   -1: traversing won't attempt to step into item's under the
    #   current item
    #   -2: traversing will stop immediately
    #
    # will return false if forced to stop by iteratee, true if travesing completed

    step_in = true # We will attempt to step into the current item unless iteratee will return false

    if _derived_call isnt true # if this is the original to the _each, the given item_id serves as the grid root, we don't yield it and regard it as expanded
      item_path = target_path # We don't yield an item for the root item so we "skip" it here and add no item
      expand_state = 1 # root is always expanded
    else
      item_path = target_path + item_id + "/"

      if options.expand_only
        # Check whether has children
        expandable = @_collectionItemHasChildren(item_id)
        expand_state = if expandable then @_inExpandedPaths(item_path) else -1

        iteratee_ret = iteratee item_id, item_path, expand_state
      else
        expand_state = 1 # Mark it as 1 just so it won't affect recursion

        iteratee_ret = iteratee item_id, item_path

    if iteratee_ret is -1
      step_in = false
    else if iteratee_ret is -2
      return false

    if step_in isnt false # only false means do not step in
      if (not options.expand_only or expand_state == 1) and (item_node = @grid_data.tree_structure[item_id])? # if has children
        node_child_orders = (_.keys item_node).sort(numSort)

        for child_order in node_child_orders
          traversting_res = @_naturalCollectionTreeTraversing(item_node[child_order], item_path, options, iteratee, true)

          if traversting_res is false
            # If we received false, it means iteratee wants the traversing to stop
            return false

    return true

  naturalCollectionTreeTraversing: (item_id="0", target_path, options, iteratee) ->
    # Prepare arguments for call to _naturalCollectionTreeTraversing
    #
    # IMPORTANT! these inits are EXPENSIVE don't call
    # naturalCollectionTreeTraversing in loops or recursion, prepare the items
    # args yourself and call _naturalCollectionTreeTraversing

    if _.isFunction options
      iteratee = options
      options = {}

    default_options =
      expand_only: true

    options = _.extend default_options, options

    return @_naturalCollectionTreeTraversing(item_id, target_path, options, iteratee)

  globalStateVarExist: (var_name) ->
    return @grid_data.globalStateVarExist(var_name)

  setGlobalStateVar: (var_name, new_val) ->
    return @grid_data.setGlobalStateVar(var_name, new_val)

  unsetGlobalStateVar: (var_name) ->
    return @grid_data.unsetGlobalStateVar(var_name)

  getGlobalStateVar: (var_name, default_val) ->
    return @grid_data.getGlobalStateVar(var_name, default_val)

  stateVarExist: (var_name) ->
    return @grid_data.stateVarExist(@section_obj.id, var_name)

  setStateVar: (var_name, new_val) ->
    return @grid_data.setStateVar(@section_obj.id, var_name, new_val)

  unsetStateVar: (var_name) ->
    return @grid_data.unsetStateVar(@section_obj.id, var_name)

  getStateVar: (var_name, default_val) ->
    return @grid_data.getStateVar(@section_obj.id, var_name, default_val)

GridData.installSectionManager("GridDataSectionManager", GridDataSectionManager)