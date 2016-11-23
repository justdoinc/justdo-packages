#
# IMPORTANT TERMINOLOGY
#
# `item` in all the functions below means @grid_tree item.
#
# When we refer to item from @collection we explicitly say `collection item`.
#

helpers = share.helpers

_.extend GridData.prototype,
  #
  # The basic slick grid api
  #
  getLength: -> @grid_tree.length
  getItem: (index) -> @grid_tree[index][0]

  #
  # @grid_tree shortcuts/extended info
  #
  getItemExt: (index) -> @grid_tree[index]
  getItemLevel: (index) -> @grid_tree[index][1]
  getItemPath: (index) -> @grid_tree[index][2]
  getItemExpandState: (index) -> @grid_tree[index][3]
  getItemSection: (index) -> @grid_tree[index][4]
  getItemType: (index) -> @grid_tree[index][0]._type
  getItemIsTyped: (index) -> @getItemType(index)?

  getItemRelativePath: (index) ->
    section = @getItemSection(index)

    return section.section_manager.relPath(@getItemPath(index))

  #
  # Depth and Depth Permissions
  #
  getItemNormalizedLevel: (index) ->
    # Returns the item level, with the Sections Items' level cancelled
    #
    # Will return -1 for section items, 0 for sections' root items and so on.

    item_level = @getItemLevel(index)

    if @getItemSection(index).id != "main"
      item_level -= 1

    return item_level

  getItemRelativeDepthPermitted: (index, relative_depth=0) ->
    # Returns the permitted depth value for the normalized depth equal to the current
    # item's + relative_depth (= relevant depth), relative_depth can be negative.
    #
    # If relevant depth is negative will always return -1
    #
    # Check SectionManager's @isDepthPermitted for more details about the returned
    # values

    relevant_depth = @getItemNormalizedLevel(index) + relative_depth

    if relevant_depth < 0
      return -1

    section_manager = @getItemSection(index)?.section_manager

    if section_manager?
      return section_manager.isDepthPermitted(relevant_depth)
    
    return -1

  getItemIsMovable: (index) ->
    # Movability is an attribute of @collection item's only (null typed items).
    #
    # Item's movability depends on its section's permitted_depth option (check section's README)
    #
    # Return:
    #  -1 if item is not movable
    #   0 if item is movable in all the *section's* depths (we don't support intra-section move)
    #   1 if item is movable only from/to non-section's root level (normalized level > 0).
    #   2 XXX NOT IMPLEMENTED YET if item is movable only from/to non-section's root level - only in its top-level-parent subtree.

    type = @getItemType(index)

    if type?
      # Only @collection item's are movable (null type)
      return -1

    section = @getItemSection(index)
    item_norm_level = @getItemNormalizedLevel(index)

    return section.section_manager.isDepthPermitted(item_norm_level)

  #
  # Foreign Keys
  #
  extendObjForeignKeys: (obj, options) ->
    # XXX this is the right place to implement caching mechanism for foreign keys
    # docs for fields the user is interested to cache
    #
    # obj: an obj document to be extended
    # options:
    #   in_place: true by default. if true , we'll augment the obj received
    #             if false a new obj will return
    #   foreign_keys: null by default. If is array only the foreign keys
    #                 listed in the array will be extended

    # doc will be returned under a new property named after the foreign_key
    # if foreign_key name ends with _id - without the "_id"
    # otherwise "_doc" will be added

    # Reactive resource

    if options.in_place is false # considered true by default
      # Copy obj to new doc
      obj = _.extend {}, obj

    # Get the list of all the foreign keys from the
    # @_grid_data_core._foreign_keys_trackers object - we use it
    # only for this data - nothing else
    #
    # XXX optimize - no need to do this more then once!
    all_foreign_keys = _.keys @_grid_data_core._foreign_keys_trackers

    foreign_keys = options.foreign_keys
    if not foreign_keys?
      # Extend all
      foreign_keys = all_foreign_keys

    if _.isEmpty foreign_keys
      @logger.debug "extendObjForeignKeys: No foreign keys to extend"

      return obj

    for foreign_key in foreign_keys
      if foreign_key not in all_foreign_keys
        @logger.warn "extendObjForeignKeys: Unknown foreign key #{foreign_key} provided, skipping" 

        continue

      id_suffix_regex = /_id$/
      if id_suffix_regex.test(foreign_key)
        # If ends with _id just remove _id
        extended_field_name = foreign_key.replace id_suffix_regex, ""
      else
        # Else add "_doc" ending
        extended_field_name += "_doc"

      obj[extended_field_name] =
        @schema[foreign_key].grid_foreign_key_collection().findOne(obj[foreign_key])

    return obj

  getItemWithForeignKeys: (index, foreign_keys) ->
    @extendObjForeignKeys @getItem(index),
      in_place: false
      foreign_keys: foreign_keys

  #
  # Sections/Paths information
  #
  each: (path, options, iteratee) -> # path should be absolute path
    # each(path, [options, ]iteratee)
    #
    # Prepare arguments for call to _each (defined in grid-sections.coffee,
    # read extended docs there)
    #
    # IMPORTANT! these inits are expensive don't call each in loops or
    # recursion, prepare the items args yourself and call _each

    if _.isFunction options
      iteratee = options
      options = {}

    default_options =
      expand_only: false
      filtered_tree: false # keep in mind @each is reused in section-manager-proto that don't have this option

    options = _.extend default_options, options

    return @_each path, options, iteratee # defined in grid-sections.coffee

  getPathSection: (path) ->
    # Return the section object in @sections of the provided path
    # or null, if couldn't found path (doesn't require path to be in @grid_tree)

    if (row = @getPathGridTreeIndex(path))?
      # If path is in @grid_tree, we can use @getItemSection
      return @getItemSection(row)

    # If path isn't in @grid_tree...
    first_level_path = path.substr(0, path.indexOf("/", 1) + 1)

    if (section = @section_path_to_section[first_level_path])?
      return section

    if (section = @section_path_to_section["/"])? # main section exists
      return section

    return null

  getPathGridTreeIndex: (path) ->
    # Returns path index in @grid_tree (even if filtered out)
    #
    # null if path doesn't exist in the current @grid_tree
    if (index = @_typed_items_paths_map_to_grid_tree_indices[path])?
      return index
    else if (potential_indices = @_items_ids_map_to_grid_tree_indices[helpers.getPathItemId(path)])?
      for index in potential_indices
        if @grid_tree[index][2] == path
          return index

    return null

  getPathRelativePath: (path) ->
    # Return null if path doesn't exist

    index = @getPathGridTreeIndex(path)

    if not index?
      return null

    return @getItemRelativePath(index)

  pathInGridTree: (path) ->
    # Returns true if path exist in @grid_tree (even if filtered out)
    @getPathGridTreeIndex(path)?

  pathExist: (path) ->
    # Note: not filters aware, not reactive

    # return true if path exists false otherwise
    path = helpers.normalizePath path

    if not (section = @getPathSection(path))?
      # Path is under no known section
      return -1

    return section.section_manager.isPathExist path

  getPathNaturalCollectionTreeInfo: (path) ->
    # If path's corresponds to the natural @collection's tree representation we return
    # an object of the following form:
    #
    # {
    #   item_id:   the path's basename - if is a known @collection item id
    #   parent_id: If path is only one level, or if path is a top-level item in a section
    #              will be "0" - only if "0" is parent of item_id.
    #              If the parent path's basename is a known @collection item id will be that
    #              id - only if that id is a parent of item_id.
    #              In any other case will be null.
    #   order:     Will be null if parent_id is null, otherwise item_id's order under parent_id.
    # }
    #
    # If we can't even find the item_id we return null.
    #
    # Notes:
    #
    # * If path is "/" return null.
    # * We assume path exists. We don't check whether it exists.

    if helpers.isRootPath path
      return null

    path_section = @getPathSection(path)
    relative_path = path_section.section_manager.relPath(path)

    if relative_path == "/"
      # path is the section's section item, not an @collection item.
      return null

    item_id = helpers.getPathItemId(relative_path)

    if not(item_id of @items_by_id)
      # Path doesn't point to a known item_id
      return null

    parent_relative_path = helpers.getParentPath(relative_path)
    if parent_relative_path == "/"
      parent_item_id = "0"
    else
      parent_item_id = helpers.getPathItemId(parent_relative_path)

      if not(parent_item_id of @items_by_id)
        parent_item_id = null

    order = null
    if parent_item_id?
      item = @items_by_id[item_id]
      parent_item_details = item.parents[parent_item_id]

      if parent_item_details?
        order = parent_item_details.order
      else
        parent_item_id = null # not really a parent

    details =
      item_id: item_id
      parent_id: parent_item_id
      order: order

    return details

  #
  # Expand/Collapse
  #
  _inExpandedPaths: (path) -> path of @_expanded_paths

  expandPath: (path, _force=false) ->
    # If _force is set to true, we won't check whether the path
    # exists before mark it as expanded in the datastructure
    # should be used only by internal apis

    path = helpers.normalizePath path

    if helpers.isRootPath path
      # root always expanded
      return

    if _force or @pathExist path
      for ancestor_path in helpers.getAllAncestorPaths(path)
        if not @_inExpandedPaths(ancestor_path)
          @_structure_changes_queue.push ["expand_path", [ancestor_path]]
          @_set_need_flush()
    else
      @_error "unknown-path", "Can't expand unknown path: #{path}", {path: path}

    return

  collapsePath: (path) ->
    path = helpers.normalizePath(path)

    if helpers.isRootPath path
      # root always expanded
      return

    if @_inExpandedPaths(path)
      @_structure_changes_queue.push ["collapse_path", [path]]
      @_set_need_flush()

  toggleItem: (index) ->
    if @_inExpandedPaths(@getItemPath index) # XXX shouldn't use filters aware op
      @collapseItem index
    else
      @expandItem index

  expandItem: (index) -> @expandPath(@getItemPath index)

  collapseItem: (index) -> @collapsePath(@getItemPath index)

  #
  # Collection items info
  #
  getCollectionItemIdPath: (item_id) ->
    # Returns the first path in @grid_tree that leads to the requested item_id of @collection.
    #
    # Will return null if no such item_id in the tree.

    # Note, we don't use getAllCollectionItemIdPaths() to implement this
    # function, so we can apply optimization that stop the scanning as soon as
    # we find a path for the item in the tree.

    if item_id == "0"
      return "/"

    item_path = null
    @_each "/", {expand_only: false, filtered_tree: false}, (section, item_type, item_obj, path, expand_state) ->
      if item_obj._id == item_id
        item_path = path

        return -2
    
    return item_path

  getAllCollectionItemIdPaths: (item_id) ->
    # Returns an array with all the paths in @grid_tree that leads to the
    # requested item_id of @collection, in their order in the tree.
    #
    # Will return undefined if we can't find item_id in the tree.

    if item_id == "0"
      return "/"

    paths = []
    @_each "/", {expand_only: false, filtered_tree: false}, (section, item_type, item_obj, path, expand_state) ->
      if item_obj._id == item_id
        paths.push(path)

        # Let the each keep running
        return undefined

    if _.isEmpty paths
      paths = undefined

    return paths

  #
  # Filters Management
  #
  setFilter: (filter_query) -> @filter.set(filter_query)

  #
  # Low level filters info
  #
  getGridTreeFilterState: ->
    @_grid_tree_filter_state_updated.get()

    return @getGridTreeFilterStateNonReactive()

  getGridTreeFilterStateNonReactive: -> @_grid_tree_filter_state

  isActiveFilter: ->
    @getGridTreeFilterState()?

  isActiveFilterNonReactive: ->
    @getGridTreeFilterStateNonReactive()?

  #
  # @grid_tree item's filter info
  #
  getItemPassFilter: (index) ->
    # Returns true if given index exists in @grid_tree and pass the current filter.
    # If there's no filter and index exists in @grid_tree, will return true.
    # Returns false otherwise.

    if index < 0 or index >= @getLength()
      return false

    if not @isActiveFilterNonReactive()
      # if no filter applied, all items are passing
      return true

    if @_grid_tree_filter_state[index][0] > 0
      return true

    return false

  #
  # Path's filters info
  #
  pathPassFilter: (path) ->
    # Non reactive
    #
    # Return true if path pass current filter
    #
    # IMPORTANT!
    #   * path doesn't have to be in the expanded sub-tree, the entire tree
    #     is checked
    #   * Currently we don't support typed items filters
    #   * If there's no active filter, will always return true, even
    #     if path doesn't exist.

    if helpers.isRootPath path
      return true

    if not @isActiveFilterNonReactive()
      # if no filter applied, all items are passing
      return true

    item_id = helpers.getPathItemId(path)

    if item_id of @_filter_collection_items_ids
      return true

    return false

  pathHasPassingFilterDescendants: (path, _non_optimized) ->
    # Non reactive
    #
    # Returns true if path has descendants that pass the filter, false
    # in any other situation (incl in cases where we can't find the path's
    # item in @grid_tree)
    #
    # Note: traverse the entire tree and not only the expanded sub-tree
    #
    # If _non_optimized is true we won't use @_each but the section_manager's
    # _hasPassingFilterDescendants.
    # @_each is optimized when traversing for any sub-path that exist in @grid_tree
    # but since it depends on @grid_tree and @_grid_tree_filter_state for
    # the optimizations, if they aren't ready we can't use it.

    if _non_optimized is true
      section = @getPathSection(path)

      if not section?
        @logger.warn("@pathHasPassingFilterDescendants: provided path is not part of any section")

        return false

      return section.section_manager._hasPassingFilterDescendants(path)

    has_passing_filter_descendants = false

    @_each path, {expand_only: false, filtered_tree: true}, ->
      has_passing_filter_descendants = true

      return -2 # stop immediately

    return has_passing_filter_descendants

  pathPartOfFilteredTree: (path, _non_optimized) ->
    # Non reactive
    #
    # Returns true if path or its descendants pass the filter, false in any other
    # situation
    #
    # Important:
    # * If there's no active filter, will always return true, even
    # if path doesn't exist. (@pathPassFilter doesn't check existence, if necessary
    # check existence yourself first)
    # * Root path is always considered as passing the filter
    # * traverse the entire tree and not only the expanded sub-tree

    if helpers.isRootPath path
      return true

    if @pathPassFilter(path) or @pathHasPassingFilterDescendants(path, _non_optimized)
      return true

    return false

  #
  # Reactive filter aware methods
  #

  #
  # All the functions beginning with filterAware are reactive resources depending on:
  # * @invalidateOnRebuild() : meaning, invalidation occurs following updates to:
  #     * @grid_tree
  # * @isActiveFilter() : meaning, invalidation occurs following updates to:
  #     * @_filter_collection_items_ids
  #     * @_grid_tree_filter_state
  #

  filterAwareGetItemExpandState: (index) ->
    @filterAwareGetPathExpandState(@getItemPath(index))
  filterAwareGetPathExpandState: (path) ->
    # Gets a path that has an item in @grid_tree and returns its expand state,
    # taking filters into account if there's an active filter.

    # -1 if path has no children
    # 0 if path has children and is collapsed
    # 1 if path has children and is expanded

    # Returns null if:
    #   * path doesn't exist in @grid_tree
    #   * path is hidden by the filter

    @invalidateOnRebuild()
    active_filter = @isActiveFilter()

    if helpers.isRootPath path
      # Root is always expanded
      return 1

    if not (index = @getPathGridTreeIndex(path))?
      return null

    expand_state = @getItemExpandState(index)

    if not active_filter
      return expand_state

    item_filter_state = @_grid_tree_filter_state[index][0]

    if item_filter_state == 0 # Item isn't presented in filtered tree
      return null

    if item_filter_state == 3 # Item is leaf in filtered tree
      return -1
  
    return expand_state # Item has children in filtered tree, expand state is same as if we are non-filtered state

  filterAwareGetItemHasChildren: (index) ->
    @filterAwareGetPathHasChildren(@getItemPath(index))
  filterAwareGetPathHasChildren: (path) ->
    # Gets a non-root path that has an item in @grid_tree and checks whether it has children,
    # taking filters into account if there's an active filter.

    # Returns 0 if path is a leaf, hidden, hidden by filter or doesn't exist
    #         1 if path has children
    #         2 if path has children - but all are hidden by active filter

    # IMPORTANT: this function always return 1 for the root path, use other methods
    #            to check root situation

    if helpers.isRootPath path
      logger.warn "filterAwareGetPathHasChildren: the root path is invalid input for this method"
      # Root is always expanded
      return 1

    @invalidateOnRebuild()
    active_filter = @isActiveFilter()

    expand_state = @filterAwareGetPathExpandState(path)

    if not expand_state? # If path doesn't exist, hidden by filter
      return 0

    if expand_state != -1 # If expand state isn't -1 there are children
      return 1

    if not active_filter # path is a leaf
      return 0

    index = @getPathGridTreeIndex(path) # no need to check existence, checked by filterAwareGetPathExpandState already 

    # There's a filter, check if all children are hidden due to the filter
    if @getItemExpandState(index) != -1
      # Not a leaf in the non filtered tree, all children hidden by filter
      return 2

    return 0

  filterAwareGetNextLteLevelPath: (path, within_section) ->
    # Returns null if there's no such path or if provided
    # path doesn't exist.

    if not (row_id = @getPathGridTreeIndex(path))?
      return null

    return @getItemPath(@filterAwareGetNextLteLevelItem(row_id, within_section))

  filterAwareGetNextLteLevelItem: (index, within_section=true) ->
    # Gets an index of @grid_tree and returns the next index in the tree
    # that is positioned in either the same level or in a lower level.

    @invalidateOnRebuild()
    active_filter = @isActiveFilter()

    if within_section
      section = @getItemSection(index)
      limit = section.end
    else
      limit = @getLength()

    item_level = @getItemLevel(index)

    next_item_row = index + 1
    while next_item_row < limit
      if active_filter
        # Check if item passed the filter

        # XXX Note that we have in @_grid_tree_filter_state info that can be used to optimize
        # this (info about which is first/last visible)
        if @_grid_tree_filter_state[next_item_row][0] == 0 # means not passing filter
          next_item_row += 1
          continue

      if @getItemLevel(next_item_row) <= item_level
        return next_item_row

      next_item_row += 1

    # None found
    return null

  filterAwareGetNextItem: (index, within_section=true) ->
    # Returns null if index is the last item (last visible item if filters enabled)
    # Filter aware

    @invalidateOnRebuild()
    active_filter = @isActiveFilter()

    if within_section
      section = @getItemSection(index)
      limit = section.end
    else
      limit = @getLength()

    next_item_row = index + 1

    if active_filter
      # If there's an active filter, look for visible prev item

      # XXX Note that we have in @_grid_tree_filter_state info that can be used to optimize
      # this (info about which is first/last visible)
      while next_item_row < limit
        if @getItemPassFilter(next_item_row)
          break

        next_item_row += 1     

    if next_item_row >= limit
      return null

    return next_item_row

  filterAwareGetPreviousItem: (index, within_section=true) ->
    # Returns null if index is the first item (first visible item if filters enabled)
    # Filter aware

    @invalidateOnRebuild()
    active_filter = @isActiveFilter()

    previous_item_row = index - 1

    if within_section
      section = @getItemSection(index)
      limit = section.begin
    else
      limit = 0

    if active_filter
      # If there's an active filter, look for visible next item

      # XXX Note that we have in @_grid_tree_filter_state info that can be used to optimize
      # this (info about which is first/last visible)
      while previous_item_row >= limit
        if @getItemPassFilter(previous_item_row) # means passing filter
          break

        previous_item_row -= 1

    if previous_item_row < limit
      return null

    return previous_item_row

  filterAwareGetFirstPassingFilterItem: (index, prev, within_section) ->
    # Returns the index of the first visible item in @grid_tree starting from `index`
    # in the given direction (up if `prev` is true, down otherwise).
    #
    # If index itself pass the filter it will be returned.

    @invalidateOnRebuild()
    active_filter = @isActiveFilter()

    if @getItemPassFilter(index)
      return index

    if prev
      return @filterAwareGetPreviousItem(index, within_section)

    return @filterAwareGetNextItem(index, within_section)

  filterAwareGetNextPath: (path, within_section) -> @_getNeighboringPath(path, false, within_section)
  filterAwareGetPreviousPath: (path, within_section) -> @_getNeighboringPath(path, true, within_section)
  _getNeighboringPath: (path, prev, within_section) ->
    # returns the prev path if prev = true; the next path
    # otherwise.
    # Return null if there's no such path or if provided path is unknown

    # Filters aware
    row_id = @getPathGridTreeIndex(path)

    if not row_id?
      return null

    if prev
      item = @filterAwareGetPreviousItem row_id, within_section
    else
      item = @filterAwareGetNextItem row_id, within_section

    if not item?
      return null

    return @getItemPath item

  filterAwareGetItemExtendedDetails: (index) ->
    # Gets a grid tree index and returns extended filter-aware information
    # about it.

    # Returns null if there's no such index

    if not index?
      return null

    @invalidateOnRebuild()
    active_filter = @isActiveFilter()

    item = @grid_tree[index]

    if not item?
      return null

    [doc, level, path, _es, section] = item
    type = @getItemType(index)
    expand_state = @filterAwareGetPathExpandState(path)

    natural_collection_info = null
    if not type? # not typed item try get information about the parent path
      natural_collection_info = @getPathNaturalCollectionTreeInfo(path)

    ext =
      index: index

      doc: doc
      level: level
      path: path

      type: type
      section: section
      expand_state: expand_state

      natural_collection_info: natural_collection_info

    return ext
