helpers = share.helpers

default_options =
  tree_root_item_id: "0"

  # Overrides the constractor's prototypical @rootItems
  rootItems: null

  # Overrides the constractor's prototypical @root_items_sort_by
  root_items_sort_by: null

NaturalCollectionSubtreeSection = (grid_data_obj, section_root, section_obj, options) ->
  GridData.sections_managers.GridDataSectionManager.call @, grid_data_obj, section_root, section_obj, options

  @_rootItemsComputation = null

  @options = _.extend {}, default_options, options

  if (rootItems = @options.rootItems)?
    @rootItems = rootItems

  if (itemsTypesAssigner = @options.itemsTypesAssigner)?
    @itemsTypesAssigner = itemsTypesAssigner

  if (root_items_sort_by = @options.root_items_sort_by)?
    @root_items_sort_by = root_items_sort_by

  return @

Util.inherits NaturalCollectionSubtreeSection, GridData.sections_managers.GridDataSectionManager

_.extend NaturalCollectionSubtreeSection.prototype,
  # if rootItems is null, the section will yield the entire naturalCollectionTree (starting from @options.tree_root_item_id)
  # if rootItems is a method it is expected to return:
  #   1. An object whose keys are items_ids of the items that should be used as the roots
  #      of the section's natural sub-trees.
  #   2. An array, whose items are objects that has the _id property of the items that should
  #      be used as roots, e.g. {_id: "xx"}.
  #      all other properties will be ignored.
  #      The order of the array will be the default order in which the items will be listed.
  #      The @root_items_sort_by can override that
  #
  #      !IMPROTANT if @yield_root_items is false, the original order of
  #      the array will be ignored, sort will be governed only by the
  #      @root_items_sort_by options
  #   3. Null/Undefined, in such a case we'll behave as if rootItems isn't defined.
  #      This was added 2019-12-17 to allow sections to set custom rootItems() conditional to the section state
  #      vars.
  #        
  rootItems: null


  # fallbackItemsDictionary can be a method that returns an object whose keys are items ids
  # and values are items documents.
  #
  # If we can't find items in the default grid collection as cached by @grid_data.items_by_id
  # we will try to look for the items in the object returned by the fallbackItemsDictionary
  fallbackItemsDictionary: -> {}

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

  # root items filter:
  #
  # Note if @rootItems is not set, this property has no effect.
  #
  # If @rootItemsFilter is set it will get as its first parameter the output of
  # @rootItems. Letting you change it before NaturalCollectionSubtreeSection start
  # processing it.
  #
  # See DetachedDataSubTreesSection to see usage example.
  #
  # If you want to change the received root items you *must* create
  # a shallow copy of the passed value, do not edit by reference.
  #
  # Can be a reactive resource. Note that @_rootItems() calls this
  # method, and @_rootItems is run by NaturalCollectionSubtreeSection
  # in a computations where necessary, so no additional computation
  # needs to be introduced by you here.
  #
  # Notes:
  # 
  # 1. the main difference between @rootItemsFilter and @top_level_items
  # is that @rootItemsFilter works directly on @rootItems() output, and not
  # on the actual top level items of the section after @yield_root_items
  # was taken into account. Also, rootItemsFilter() is run only if @rootItems()
  # is defined.
  #
  # 2. @rootItemsFilter will get the root items in the same structure
  # @rootItems() provided them. (there are two potential data structures
  # @rootItems() can return, if you know in advance which one it will be,
  # you don't need to worry about handling the other as well).
  rootItemsFilter: null

  # top level items filter:
  #
  # By top level items we mean here the top-level items of the section
  # (so if the section is under the path /s/), root items are items
  # of paths: /s/item_id/
  #
  # You need to implement two methods to implement top items filter
  # you'll set them inside an object of the following structure:
  #
  # {
  #   singleItem: (item_id) -> Should return true if item_id pass the filter, false otherwise
  #   allItems: (top_level_items_objs) -> Read docs below
  # }
  #
  # * top_level_items_filter.singleItem(item_id):
  #
  # Receives a single top level item id (String) and should return true
  # if it passes the filter, false otherwise.
  #
  # @ is the section manager object
  #
  # * top_level_items_filter.allItems(top_level_items_objs):
  #
  # Will receive as its first argument all the top level items, after we
  # calculated them based on @rootItems, taking into account @rootItemsFilter
  # and the @yield_root_items value. Giving you last chance to change that
  # list of item before adding it to the section.
  #
  # top_level_items_objs will be an array of the top level items objects
  # as stored in @grid_data.items_by_id .
  #
  # You should return an array of the same structure. You shouldn't
  # change the objects items objects (unsupported use, might result
  # in bugs). You are allowed to change the array in place.
  #
  # @ is the section manager object
  #
  # Check DetachedDataSubTreesSection to see usage example.
  #
  # Implementation note:
  #
  # We require defining both singleItem and allItem since in some contexts
  # we don't calculate the full list of top level items, and we don't want
  # to have to do that just to be able to call the top levels items filter.
  #
  # From the other hand, when we have the full list, passing the entire list
  # at once is much more efficient than one item after the other, and also
  # allows you to define optimizations.
  #
  # Another use case that was took into consideration was implementation of
  # items limit mechanism, such a mechanism is possible to implement properly
  # only with the allItems() method. 
  #
  # We don't run any check to see whether both functions are defined, and not
  # implementing both of them will result in a crash.
  top_level_items_filter: null

  # root_items_sort_by a function that will be used to sort the top level
  # items, the function should be constructed according to Underscore's
  # sortBy iteratee
  #
  # Note: root_items_sort_by is relevant only if @rootItems or options.rootItems
  # aren't not null, if they are null, we will use the natural collection
  # items order without applying filter
  root_items_sort_by: null

  _rootItems: ->
    # Calls @rootItems() and pass it through @rootItemsFilter() if exists
    # called internally, only in places where we check first whether @rootItems
    # exists
    root_items = @rootItems()

    if @rootItemsFilter?
      root_items = @rootItemsFilter(root_items)

    return root_items

  _isPathExist: (relative_path) ->
    tree_structure = @grid_data.tree_structure

    path_array = helpers.getPathArray(relative_path)

    if not @rootItems? or not (root_items = @_rootItems())?
      # If @rootItems isn't set, or if root_items returned null
      current_node = tree_structure[@options.tree_root_item_id]
      current_node_id = @options.tree_root_item_id
    else
      # If is a sub-trees section, check whether relative_path's top level item
      # is part of our @rootItems
      top_level_item_id = path_array.shift()

      isItemIdInRootItems = (item_id) ->
        # read comment on @rootItems output structure above.
        if _.isArray root_items
          return _.find(root_items, (item) -> item._id == item_id)?
        else
          return item_id of root_items

      if @yield_root_items
        if not isItemIdInRootItems(top_level_item_id)
          return false
      else
        # Check whehter the top level item id has a parent in root_items
        # (if @yield_root_items is false, only the children of the root items
        # are printed)
        if not (top_level_item_obj = @grid_data.items_by_id[top_level_item_id])? and not (top_level_item_obj = @fallbackItemsDictionary()[top_level_item_id])?
          return false

        parent_found = false
        for parent_id of top_level_item_obj.parents
          if isItemIdInRootItems(parent_id)
            parent_found = true

        if not parent_found
          return false

      if @top_level_items_filter?
        if not @top_level_items_filter.singleItem.call(@, top_level_item_id)
          return false

      if path_array.length == 0
        # If there are no further items in the path, that's it, we found it
        return true

      current_node = tree_structure[top_level_item_id]
      current_node_id = top_level_item_id

    if not current_node?
      return false

    while path_array.length > 0
      cur_id = path_array.shift()

      next_node = null
      for order, item_id of current_node
        if item_id == cur_id
          next_node = tree_structure[cur_id]
          next_node_id = cur_id

          break
      
      if not next_node?
        # node not found in tree_structure, check if it exists in order_overridden_items
        
        # XXX From TY: this for loop can be optimized if we change the structure of order_overridden_items
        # back to order_overridden_items[parent_id][order] instead of order_overridden_items['parent_id:order'].
        #
        # However, the chance we'll run into this for loop and the size of order_overridden_items is big
        # is pretty low.
        # 
        # So, I'm leaving it as it for now.
        for key, items of @grid_data._grid_data_core.order_overridden_items
          if key.substring(0, key.indexOf(":")) == current_node_id and items.has(cur_id)
            next_node = tree_structure[cur_id]
            next_node_id = cur_id
            break

      if next_node?
        current_node = next_node
        current_node_id = next_node_id
      else if not(next_node is null) and path_array.length == 0
        # Do nothing, path is a leaf, while loop is done here
      else
        return false

    return true

  _each: (relative_path, options, iteratee) ->
    _naturalCollectionTreeTraversingIteratee = (item_id, item_path, expand_state) =>
      item_obj = @grid_data.items_by_id[item_id] or @fallbackItemsDictionary()[item_id]

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

        root_items = @_rootItems()
    else
      root_items = @_rootItems()

    if not root_items?
      # If @rootItems returned null, we behave as if it isn't set.
      path_item_id = @options.tree_root_item_id

      return forwardHandling()

    # Find all top level items
    top_level_items = null
    if @yield_root_items
      top_level_items = root_items
    else
      # add to top_level_items only the children of the root items
      top_level_items = {}

      addChildrenAsTopLevelItem = (item_id) =>
        # adds the childrens of item_id to top_level_items
        # in the @rootItems object output format
        if (root_item_node_struct = @grid_data.tree_structure[item_id])?
          for order, child_id of root_item_node_struct
            top_level_items[child_id] = true

      # read comment on @rootItems output structure above.
      if _.isArray root_items
        for item in root_items
          addChildrenAsTopLevelItem(item._id)
      else
        for root_item_id of root_items
          addChildrenAsTopLevelItem(root_item_id)

    fallback_items_dictionary = @fallbackItemsDictionary()

    if _.isArray top_level_items
      top_level_items_objs = _.map(top_level_items, ((item) -> @grid_data.items_by_id[item._id] or fallback_items_dictionary[item._id]), @)
    else
      top_level_items_objs = _.map(top_level_items, ((_ignore, id) -> @grid_data.items_by_id[id] or fallback_items_dictionary[id]), @)

    if @top_level_items_filter?
      top_level_items_objs =
        @top_level_items_filter.allItems.call(@, top_level_items_objs)

    if @root_items_sort_by?
      top_level_items_objs = _.sortBy(top_level_items_objs, @root_items_sort_by, @)

    for top_level_items_obj in top_level_items_objs
      if not top_level_items_obj?
        # top_level_items_obj will be undefined for items in top_level_items which their
        # ids are no longer in minimongo (e.g removed).
        continue
      
      top_level_item_id = top_level_items_obj._id

      if @grid_data.items_by_id[top_level_item_id]? or fallback_items_dictionary[top_level_item_id]?
        traversing_ret = @_naturalCollectionTreeTraversing top_level_item_id, relative_path, options, _naturalCollectionTreeTraversingIteratee, true

        if traversing_ret is false
          return false
      else
        logger.warn "NaturalCollectionSubtreeSection: couldn't find a top level item object for", top_level_item_id

    return true

  destroy: ->
    # Upon destroy, stop @_rootItemsComputation, in case one was set
    if @_rootItemsComputation?
      @_rootItemsComputation.stop()


GridData.installSectionManager("NaturalCollectionSubtreeSection", NaturalCollectionSubtreeSection)
