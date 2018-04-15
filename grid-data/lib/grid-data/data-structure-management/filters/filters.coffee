helpers = share.helpers

_.extend GridData.prototype,
  _initFilters: ->
    @filter = new ReactiveVar(null, (a, b) -> JSON.sortify(a) == JSON.sortify(b))
    # item_ids present in @filter_independent_items array will always pass the filter
    @filter_independent_items = new ReactiveVar(null, (a, b) -> JSON.stringify(a) == JSON.stringify(b))
    @_filter_tracker = null
    @_filter_collection_items_ids = null
    @_grid_tree_filter_state = null

    # We use the following two to add core-api's @getGridTreeFilterState() reactive
    # layer
    @_grid_tree_filter_state_updated_count = 0
    @_grid_tree_filter_state_updated = new ReactiveVar(0)

    @once "_perform_deferred_procedures", ->
      @_init_filter_tracker()

  _init_filter_tracker: ->
    # Track changes to current filter query
    if not @_destroyed and not @_filter_tracker?
      @_filter_tracker = Tracker.autorun => @_updateFilterItems()

  _updateFilterItems: ->
    @logger.debug "_updateFilterItems"
    # Update @_filter_collection_items_ids based on current @filter

    filter = @filter.get()

    if not filter?
      # If filter cleared, init @_filter_collection_items_ids
      @_filter_collection_items_ids = null
    else
      _filter_collection_items_ids = {}

      query = filter
      query_options = 
        fields:
          _id: 1

      @collection.find(query, query_options).forEach (item) ->
        _filter_collection_items_ids[item._id] = true

      # Add the filter independent items
      if (filter_independent_items = @filter_independent_items.get())?
        for item_id in filter_independent_items
          _filter_collection_items_ids[item_id] = true

      @_filter_collection_items_ids = _filter_collection_items_ids

    # If init is undergoing, we don't want to call @_updateGridTreeFilterState()
    # as it'll be called anyway on first rebuild
    if @_initialized
      Tracker.nonreactive =>
        @_updateGridTreeFilterState()

    @logger.debug "@_filter_collection_items_ids updated"

  _updateGridTreeFilterState: ->
    # Filter visible items against @_filter_collection_items_ids, set result to @_grid_tree_filter_state

    @logger.debug "Update grid tree filter"

    filter = @filter.get()

    if not filter?
      if @_grid_tree_filter_state?
        @_grid_tree_filter_state = null

        @emit "grid-tree-filter-cleared"
    else
      if not @_filter_collection_items_ids?
        @logger.warn "@_updateGridTreeFilterState called with active filter but @_filter_collection_items_ids is null"

        return

      # calculate filtered tree
      # [item_filter_state, special_position, is_leaf_of_visible_filtered_tree]
      #
      # item_filter_state:
      #   0: didn't pass filter
      #   1: descendant pass filter, inner node in filtered tree
      #   2: pass filter and descendant pass filter, inner node in filtered tree
      #   3: pass filter, a leaf in the filtered tree
      #
      # special_position
      #   0: not special
      #   1: first passing item
      #   2: last passing item
      #   3: only passing item
      #
      # is_leaf_of_visible_filtered_tree:
      #   0: The item either didn't pass the filter, or has visible children in the 
      #      current tree.
      #   1: The item or one of its descendants passed the filter, and either doesn't
      #      have descendants that pass the filter, or has descendants that passed the
      #      filter but is collapsed.

      @_grid_tree_filter_state = []

      if @getLength() > 0
        # When we find a node that is part of the filtered tree parent_level
        # will hold the level of its parent
        parent_level = null
        # inner_node is true when we find an inner node
        inner_node = false

        prev_visible_item_level = null
        
        last_visible_found = false
        first_visible_index = null
        for section_index in [(@sections.length - 1)..0]
          # loop over the items by looping over the section, in order to have the section
          # object of each item efficiently 

          section = @sections[section_index]

          if section.empty
            continue

          i = section.end
          while i > section.begin
            # we didn't use coffe's for in order to optimize 
            i -= 1

            [child, level, path, expand_state] = @grid_tree[i]

            @_grid_tree_filter_state[i] = [0, 0, 0]

            inner_node = false
            if parent_level?
              if level == parent_level
                if level == 0
                  parent_level = null
                else
                  parent_level -= 1

                inner_node = true

            if not inner_node and expand_state == 0
              # If node is collapsed, we need to check whether one of its descendants
              # pass the filter, before we can conclude whether it's an inner_node of the
              # filtered tree or not.
              # We have to do it in order to be able to present its expand/collapse toggle button
              # in the filtered tree only if it has descendant/s that pass the filter

              # Note we use section.section_manager._hasPassingFilterDescendants and not
              # grid_data's hasPassingFilterDescendants since without @_grid_tree_filter_state
              # we don't have ability to optimize anyway (and grid_data's hasPassingFilterDescendants
              # will do redundant path section check)
              if section.section_manager._hasPassingFilterDescendants(path)
                if level > 0            
                  parent_level = level - 1

                inner_node = true

            if inner_node
              # at the minimum it's 1, might turn out to be 2 later
              @_grid_tree_filter_state[i][0] = 1

            if child._id of @_filter_collection_items_ids
              if level > 0
                parent_level = level - 1

              if inner_node
                @_grid_tree_filter_state[i][0] = 2
              else
                @_grid_tree_filter_state[i][0] = 3

            if @_grid_tree_filter_state[i][0] > 0
              first_visible_index = i
              if not last_visible_found
                @_grid_tree_filter_state[i][1] = 2
                last_visible_found = true

              if not prev_visible_item_level? or prev_visible_item_level <= level
                @_grid_tree_filter_state[i][2] = 1

              prev_visible_item_level = level
              

        if first_visible_index?
          if @_grid_tree_filter_state[first_visible_index][1] == 2
            @_grid_tree_filter_state[first_visible_index][1] = 3
          else
            @_grid_tree_filter_state[first_visible_index][1] = 1

      @_grid_tree_filter_state_updated.set(++@_grid_tree_filter_state_updated_count)

      @emit "grid-tree-filter-updated"

  _destroy_filter_manager: ->
    if @_filter_tracker?
      @_filter_tracker.stop()