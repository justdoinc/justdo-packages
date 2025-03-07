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

  getItem: (index) ->
    # items_by_id might not be the same as the collection's id-map which is what item_val is referencing.
    #
    # We decide in this method what is the actual value we should regard.

    grid_tree_stored_item = @grid_tree[index][0]

    if not (grid_tree_stored_item_id = grid_tree_stored_item._id)?
      # Just return the stored object as is, it can't be a collection item, so no point
      # of testing whether it is up-to-date.

      return grid_tree_stored_item

    items_by_id_value = @items_by_id[grid_tree_stored_item_id]

    if not items_by_id_value?
      # We might hit that edge case in cases like the tickets queue.
      #
      # The item details isn't part of the Tasks collection for users with which the Tickets
      # Queue task isn't shared with, therefore it won't be part of the @items_by_id .
      items_by_id_value = grid_tree_stored_item

    if not @getItemIsTyped(index)
      # I anticipate 99.99% of the cases to fall into this category. Daniel C.

      # If not typed-item - return the value from @items_by_id
      return items_by_id_value

    # Typed item
    if not @getItemIsCollectionItem(index)
      return grid_tree_stored_item

    # To avoid any potential discrepancies between the object originally stored and the
    # object that is now in items_by_id (e.g. maybe the original object will be completely
    # replaced, and not just edited in place in future implementations) , just create a new
    # reference.
    # 
    # The alternative would have been to check @_grid_data_core.itemsByIdHasOwnProperty(item_id)
    # and only if there was an overriden value for items_by_id to create a new object. But again,
    # that might not be future proof.
    #
    # Very few items in a grid will ever need it, so performance isn't a concern. 
    new_item = Object.create(items_by_id_value)
    new_item._type = grid_tree_stored_item._type

    return new_item

  getItemExcludingMetadataLayer: (index) ->
    # Typed items, has a data layer. Created in:
    # packages/grid-data/lib/grid-data/data-structure-management/grid-sections/grid-sections.coffee
    # This layer is implemented as an object that inherits from the actual item.
    #
    # This method, returns the underlying item for typed items, and the item itself, for non typed
    # items.

    item = @getItem(index)

    if not @getItemIsTyped(index)
      return item

    return Object.getPrototypeOf(item)

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
  getItemIsCollectionItem: (index) ->
    if not (item_type = @getItemType(index))?
      # Not typed item, must be collection item.
      return true

    if @items_types_settings[item_type]?.is_collection_item
      return true

    return false

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
      # ignore_archived: default for this option isn't set at the moment
      # exclude_archived: default for this option isn't set at the moment

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
    if not path?
      return null
    
    if path == "/"
      return null

    if (index = @_typed_items_paths_map_to_grid_tree_indices[path])?
      return index
    else if (path_item_id = helpers.getPathItemId(path))? and (potential_indices = @_items_ids_map_to_grid_tree_indices[path_item_id])?
      for index in potential_indices
        if @grid_tree[index][2] == path
          return index

    return null

  getPathRelativePath: (path) ->
    # Return null if path doesn't exist

    # Note: If path isn't under main section it must be on the visible tree

    # If path on main section, just return it as is
    path_section = @getPathSection(path)
    if path_section?.id == "main"
      return path

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
      return false

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

  collapseAllPaths: ->
    @_structure_changes_queue.push ["collapse_all_paths"]
    @_set_need_flush()

  expandPassedFilterPaths: (depth) ->
    @_structure_changes_queue.push ["expand_passed_filter_paths", [depth]]

    @_set_need_flush()

    return

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
  getCollectionItemIdPath: (item_id, options) ->
    # Returns the first path in @grid_tree that leads to the requested item_id of @collection.
    #
    # Will return null if no such item_id in the tree.

    # Note, we don't use getAllCollectionItemIdPaths() to implement this
    # function, so we can apply optimization that stop the scanning as soon as
    # we find a path for the item in the tree.
    #
    # options itself, and all of its properties are optional.
    # Options can have the following properties:
    #
    # options.each_options Object, the options we'll pass the @_each that looks
    # for item_id. By default we pass: {expand_only: false, filtered_tree: false}
    #
    # options.allow_unreachable_paths is set we'll call getAllCollectionItemIdPaths according to its value

    each_options = {expand_only: false, filtered_tree: false}
    if (custom_each_options = options?.each_options)?
      _.extend each_options, custom_each_options

    if item_id == "0"
      return "/"
    
    if each_options.expand_only is false and each_options.filtered_tree is false
      # Following optimizations, @getAllCollectionItemIdPaths() performance are much better
      # then attempting full tree traversing for search.
      #
      # The two options that aren't supported at the moment, should be quite easy to
      # implement, once we have a bit more time. -Daniel

      optimized_item_path = @getAllCollectionItemIdPaths(item_id, true, if options?.allow_unreachable_paths? then options?.allow_unreachable_paths else undefined)?[0] or null

      return optimized_item_path

    #
    # Fallback for old alg if expand_only or filtered_tree aren't false (the performance of the following is much worse, but those options are *rarely* used).
    #

    item_path = null
    @_each "/", each_options, (section, item_type, item_obj, path, expand_state) ->
      if item_obj._id == item_id
        item_path = path

        return -2

    return item_path

  getAllCollectionItemIdPaths: (item_id, return_first=false, allow_unreachable_paths=false) ->
    self = @
    # Returns an array with all the paths in @grid_tree that leads to the
    # requested item_id of @collection, in their order in the tree.
    #
    # Will return undefined if we can't find item_id in the tree.

    # This function is reactive to changes in the underlying tree data structures

    # allow_unreachable_paths: If set to true we will include in the returned paths also paths that
    #                          are unreachable due to their ancestors being non-ignored archived tasks
    #                          in this view.

    @invalidateOnGridDataCoreStructureChange()

    same_tick_cache_key_id = "grid-data::getAllCollectionItemIdPaths::#{@_grid_data_obj_uid}::#{item_id}::#{return_first}::#{allow_unreachable_paths}"
    if JustdoHelpers.sameTickCacheExists(same_tick_cache_key_id)
      return JustdoHelpers.sameTickCacheGet(same_tick_cache_key_id)?.slice()

    if item_id == "0"
      return "/"

    sub_paths = {}
    all_paths = @_grid_data_core.getAllCollectionPaths(item_id)
    for path in all_paths
      path_parts = path.slice(1, -1).split("/")

      for sub_part, i in path_parts
        if not sub_paths[sub_part]?
          sub_paths[sub_part] = []
        sub_paths[sub_part].push path_parts.slice(i + 1).join("/")

    optimized_new_paths = []
    @_each "/", {expand_only: false, filtered_tree: false}, (section, item_type, item_obj, path, expand_state) ->
      if item_obj._id of sub_paths
        for sub_part_path in sub_paths[item_obj._id]
          # console.log {sub_paths, sub_part_path, item_obj}
          new_path = "#{path}#{if sub_part_path == "" then "" else "#{sub_part_path}/"}"
          optimized_new_paths.push new_path
          
          if return_first is true 
            if allow_unreachable_paths is true
              return -2
            else if self.isPathReachable(new_path)
              optimized_new_paths = [new_path]
              return -2

      # Step into, *ONLY* if this is a section item, we scan only the root items of each section item.
      # Note that @_each is more optimized then section_def.section_manager._each, hence we use it instead
      # of a loop of the form:
      #
      # new_paths = []
      # for section_def in @sections
      #   section_def.section_manager._each "/", {expand_only: false}, (section, item_type, item_obj, path, expand_state) =>
      #     if item_obj._id of sub_paths
      #       for sub_part_path in sub_paths[item_obj._id]
      #         # console.log {sub_paths, sub_part_path, item_obj}
      #         new_paths.push "#{section_def.path}#{item_obj._id}/#{if sub_part_path == "" then "" else "#{sub_part_path}/"}"
      #
      #     return -1

      # new_paths = _.uniq(new_paths)
      #
      # The old, non-optimized way, used to be:
      #
      # paths = []
      # console.log "OLD", JustdoHelpers.timeProfile =>
      #   @_each "/", {expand_only: false, filtered_tree: false}, (section, item_type, item_obj, path, expand_state) ->
      #     if item_obj._id == item_id
      #       paths.push(path)

      #     return

      # return

      if section.path == path
        return 1

      return -1

    optimized_new_paths = _.uniq(optimized_new_paths)

    if not allow_unreachable_paths
      optimized_new_paths = _.filter(optimized_new_paths, (path) -> self.isPathReachable(path))

    if return_first is true and optimized_new_paths.length > 1
      optimized_new_paths = [optimized_new_paths[0]]

    if _.isEmpty optimized_new_paths
      optimized_new_paths = undefined

    ret_val = optimized_new_paths
    JustdoHelpers.sameTickCacheSet(same_tick_cache_key_id, ret_val)
    return ret_val

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
    #         3 if path has children - but it is archived so it doesn't have the expand/collapse button next to it

    # IMPORTANT: this function always return 1 for the root path, use other methods
    #            to check root situation

    if helpers.isRootPath path
      logger.warn "filterAwareGetPathHasChildren: the root path is invalid input for this method"
      # Root is always expanded
      return 1

    @invalidateOnRebuild()
    active_filter = @isActiveFilter()

    if @isPathArchived(path) and not _.isEmpty(@_grid_data_core.tree_structure[GridData.helpers.getPathItemId(path)])
      return 3

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

  _isArchived: (item_id, options) ->
    # Avoid using this one directly, as it needs a preperation of ignore_archived/exclude_archived preperation
    # from the section level
    # Use: isPathArchived
    #
    # options:
    #
    # * ignore_archived: (default: false): If true we'll ignore the archived field.
    #
    # * exclude_archived (default: undefined): {}
    #     * If null/undefined non will be excluded.
    #     * If an object: keys represent items ids that we'll ignore the archived field for.

    if item_id is "0" or item_id is 0
      return false

    # If the item doesn't exist in @items_by_id we regard it as non-archived
    if not @items_by_id[item_id]?
      return false

    if options.ignore_archived is true # If we ignore_archived, all the items are considered not archived...
      return false

    if @items_by_id[item_id].archived? and (not options.exclude_archived? or item_id not of options.exclude_archived)
      return true

    return false

  isPathArchived: (path) ->
    item_id = helpers.getPathItemId(path)

    if not (path_collection_item = @items_by_id?[item_id])?
      # We don't even know that item/or the path isn't poining to a collection item e.g the /s/ shared with me path on the main tab
      return false

    if not path_collection_item.archived?
      # Nothing to do, it is for sure not archived.
      return false

    if not (section = @getPathSection(path))?
      # We don't know the section of the provided path
      return false

    # For now, we regard excluded archived root items as excluded down their tree as well
    # and not excluded only in the root.
    # If you want to change this behaviour, update the comment also under grid-sections.coffee
    exclude_archived = section.section_manager.getRootItemsExcludedFromArchivedState()

    if not exclude_archived?
      # The item is archived, and no item is excluded in this section return true
      return true

    return @_isArchived(item_id, {exclude_archived})
  
  getNonIgnoredArchivedSubPathsInPath: (path, limit=0) ->
    # Return undefined if no sub_path in path is archived
    # Will return an array that contains the archived sub-paths, from the deepest one, up to limit (so if limit is 1 we'll return 1)
    #
    # If limit is 0 we'll return all the sub-paths.

    ret = []
    for sub_path in GridData.helpers.getAllSubPaths(path).reverse()
      if @isPathArchived(sub_path)
        ret.push(sub_path)

        limit -= 1

        if limit == 0
          return ret

    if ret.length is 0
      return undefined

    return ret

  isPathReachable: (path) ->
    return not @getNonIgnoredArchivedSubPathsInPath(GridData.helpers.getParentPath(path), 1)?
