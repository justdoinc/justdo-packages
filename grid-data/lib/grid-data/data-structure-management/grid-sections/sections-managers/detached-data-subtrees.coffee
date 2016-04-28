helpers = share.helpers

default_options =
  filter: null
  sort_by: null

DetachedDataSubTreesSection = (grid_data_obj, section_root, section_obj, options) ->
  GridDataSectionManager.call @, grid_data_obj, section_root, section_obj, options

  @options = _.extend {}, default_options, options

  return @

PACK.sections_managers.DetachedDataSubTreesSection = DetachedDataSubTreesSection

Util.inherits DetachedDataSubTreesSection, GridDataSectionManager

_.extend DetachedDataSubTreesSection.prototype,
  _isPathExist: (relative_path) ->
    tree_structure = @grid_data.tree_structure

    path_array = helpers.getPathArray(relative_path)
    detached_item_id = path_array.shift()
    current_node = tree_structure[detached_item_id]

    # XXX Note code isn't DRY, DataTreeSection has following code as well. 
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
      # console.log "iteratee", @section_obj, item_id, @section_root_no_trailing_slash + item_path, expand_state
      return iteratee(@section_obj, null, @grid_data.items_by_id[item_id], @section_root_no_trailing_slash + item_path, expand_state)

    if relative_path != "/"
      # Simple case, forward request to @_naturalCollectionTreeTraversing
      path_item_id = helpers.getPathItemId(relative_path)

      return @_naturalCollectionTreeTraversing path_item_id, relative_path, options, _naturalCollectionTreeTraversingIteratee

    # Traverse the section's root

    # Find all detached items
    detached_items_ids = {} # use object and not array to efficiently avoid repetition
    for detaching_item_id of @grid_data.detaching_items_ids
      if detaching_item_id == "0"
        continue # ignore root

      if (detached_item_node_struct = @grid_data.tree_structure[detaching_item_id])?
        for order, child_id of detached_item_node_struct
          detached_items_ids[child_id] = true

    detached_items_objs = _.map(_.keys(detached_items_ids), ((id) -> @grid_data.items_by_id[id]), @)

    if @options.sort_by?
      detached_items_objs = _.sortBy(detached_items_objs, @options.sort_by, @)

    if @options.filter?
      detached_items_objs = _.filter(detached_items_objs, @options.filter)

    for detached_item_obj in detached_items_objs
      detached_item_id = detached_item_obj._id

      if @grid_data.items_by_id[detached_item_id]?
        traversing_ret = @_naturalCollectionTreeTraversing detached_item_id, relative_path, options, _naturalCollectionTreeTraversingIteratee, true

        if traversing_ret is false
          return false

    return true