helpers = share.helpers

default_options =
  tree_root_item_id: "0"

  # Overrides the constractor's prototypical @rootItems
  rootItems: null

  # The following are relevant only if @rootItems or options.rootItems
  # aren't not null, if they are null, we will use the natural collection
  # items order without applying filter
  root_items_sort_by: null # Apply sort on @rootItems output (if rootItems returns an array, this will force a different order)

NaturalCollectionSubtreeSection = (grid_data_obj, section_root, section_obj, options) ->
  GridDataSectionManager.call @, grid_data_obj, section_root, section_obj, options

  @_rootItemsComputation = null

  @options = _.extend {}, default_options, options

  if (rootItems = @options.rootItems)?
    @rootItems = rootItems

  return @

PACK.sections_managers.NaturalCollectionSubtreeSection = NaturalCollectionSubtreeSection

Util.inherits NaturalCollectionSubtreeSection, GridDataSectionManager

_.extend NaturalCollectionSubtreeSection.prototype,
  # if rootItems is null, the section will yield the entire naturalCollectionTree (starting from @options.tree_root_item_id)
  # if rootItems is a method it is expected to return an object whose keys are items_ids
  # of the items that should be used as the roots of the section's natural sub-trees. 
  rootItems: null
  # if yield_root_items is false, only the children of the rootItems will be yielded as
  # the section's top level items and not the root items themselves
  # if rootItems is null yield_root_items has no meaning
  yield_root_items: true
  # itemsTypesAssigner can be a function that will be called during the _each process
  # for every item we are going to yield, just before its yield with the item_obj and
  # the item path relative to the section root:
  #
  #   itemsTypesAssigner(item_obj, relative_path)
  #
  # it should return a string with the type that should be assigned to this item
  # or null to use the default item type 
  itemsTypesAssigner: null

  _isPathExist: (relative_path) ->
    tree_structure = @grid_data.tree_structure

    path_array = helpers.getPathArray(relative_path)

    if @rootItems?
      # If is a sub-trees section, check whether relative_path's top level item
      # is part of our @rootItems
      top_level_item_id = path_array.shift()

      root_items = @rootItems()

      if @yield_root_items
        if not (top_level_item_id of root_items)
          return false
      else
        # Check whehter the top level item id has a parent in root_items
        # (if @yield_root_items is false, only the children of the root items
        # are printed)
        if not (top_level_item_obj = @grid_data.items_by_id[top_level_item_id])?
          return false

        parent_found = false
        for parent_id of top_level_item_obj.parents
          if parent_id of root_items
            parent_found = true

        if not parent_found
          return false

      if path_array.length == 0
        # If there are no further items in the path, that's it, we found it
        return true

      current_node = tree_structure[top_level_item_id]
    else
      current_node = tree_structure[@options.tree_root_item_id]

    if not current_node?
      return false

    while path_array.length > 0
      cur_id = path_array.shift()

      next_node = null
      for order, item_id of current_node
        if item_id == cur_id
          next_node = tree_structure[cur_id]

          break

      if next_node?
        current_node = next_node
      else if not(next_node is null) and path_array.length == 0
        # Do nothing, path is a leaf, while loop is done here
      else
        return false

    return true

  _each: (relative_path, options, iteratee) ->
    _naturalCollectionTreeTraversingIteratee = (item_id, item_path, expand_state) =>
      item_obj = @grid_data.items_by_id[item_id]

      type = null
      if @itemsTypesAssigner?
        type = @itemsTypesAssigner(item_obj, item_path)

      # console.log "iteratee", @section_obj, type, item_obj, path, expand_state
      return iteratee(@section_obj, type, item_obj, @section_root_no_trailing_slash + item_path, expand_state)

    path_item_id = null
    forwardHandling = =>
      return @_naturalCollectionTreeTraversing path_item_id, relative_path, options, _naturalCollectionTreeTraversingIteratee
    if relative_path != "/"
      path_item_id = helpers.getPathItemId(relative_path)

      return forwardHandling()
    else if not @rootItems?
      # If no @rootItems method defined yield the enitre tree, starting from
      # @options.tree_root_item_id
      path_item_id = @options.tree_root_item_id

      return forwardHandling()

    # By here we have: relative_path == "/" and @rootItems is defined
    #
    # Traverse the section's top level items

    # In the first _each run, run @rootItems inside a computation so
    # in case it's a reactive resource, we'll automatically trigger
    # sections rebuild upon its invalidation 
    root_items = null
    if not @_rootItemsComputation?
      @_rootItemsComputation = Tracker.autorun (c) =>
        if @_rootItemsComputation?
          @grid_data._set_need_rebuild()

          c.stop()

          return

        root_items = @rootItems()
    else
      root_items = @rootItems()

    # Find all top level items
    top_level_items = null
    if @yield_root_items
      top_level_items = root_items
    else
      top_level_items = {}

      # add to top_level_items only the children of the root items
      for root_item_id of root_items
        if (root_item_node_struct = @grid_data.tree_structure[root_item_id])?
          for order, child_id of root_item_node_struct
            top_level_items[child_id] = true

    top_level_items_objs = _.map(top_level_items, ((_ignore, id) -> @grid_data.items_by_id[id]), @)

    if @options.root_items_sort_by?
      top_level_items_objs = _.sortBy(top_level_items_objs, @options.root_items_sort_by, @)

    for top_level_items_obj in top_level_items_objs
      top_level_item_id = top_level_items_obj._id

      if @grid_data.items_by_id[top_level_item_id]?
        traversing_ret = @_naturalCollectionTreeTraversing top_level_item_id, relative_path, options, _naturalCollectionTreeTraversingIteratee, true

        if traversing_ret is false
          return false

    return true

  _destroy: ->
    # Upon destroy, stop @_rootItemsComputation, in case one was set
    if @_rootItemsComputation?
      @_rootItemsComputation.stop()