helpers = share.helpers

default_options =
  tree_root_item_id: "0"

DataTreeSection = (grid_data_obj, section_root, section_obj, options) ->
  GridDataSectionManager.call @, grid_data_obj, section_root, section_obj, options

  @options = _.extend {}, default_options, options

  return @

PACK.sections_managers.DataTreeSection = DataTreeSection

Util.inherits DataTreeSection, GridDataSectionManager

_.extend DataTreeSection.prototype,
  _isPathExist: (relative_path) ->
    tree_structure = @grid_data.tree_structure

    path_array = helpers.getPathArray(relative_path)
    current_node = tree_structure[@options.tree_root_item_id]
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
    if relative_path == "/"
      path_item_id = @options.tree_root_item_id
    else
      path_item_id = helpers.getPathItemId(relative_path)
    
    return @_naturalCollectionTreeTraversing path_item_id, relative_path, options, (item_id, item_path, expand_state) =>
      # console.log "iteratee", @section_obj, item_id, @section_root_no_trailing_slash + item_path, expand_state
      return iteratee(@section_obj, null, @grid_data.items_by_id[item_id], @section_root_no_trailing_slash + item_path, expand_state)