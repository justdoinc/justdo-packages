PACK.filters_controllers = {}
PACK.filters_types_state_to_query_transformations = {}

row_filter_state_classes = ["f-first", "f-last", "f-passed", "f-leaf", "f-inner-node"]

isRowVisibleInFilterProjectedGrid = ($row) ->
  return $row.hasClass("f-inner-node") or $row.hasClass("f-passed")

isRowLeafInFilterProjectedGrid = ($row) ->
  return $row.hasClass("f-leaf")

_.extend GridControl.prototype,
  _initFilters: ->
    @_filters_state = null

    @once "init", =>
      # Load filters that exist before init.
      # Before init the grid-view-change won't call upon setView
      # so we need to check filters state for change
      @_updateFilterState()

    @once "destroyed", =>
      # Make sure filter-active class removed from container
      # to avoid polluting future grid control initiated on that
      # container
      @container.removeClass("filter-active")

    @on "grid-view-change", =>
      @_updateFilterState()

    @on "filter-change", (filter_state, filter_query) =>
      # Clear items that were forced to pass the previous filter
      @_grid_data.clearFilterIndependentItems()

      @_grid_data.setFilter filter_query

    @on "grid-tree-filter-updated", =>
      active_path = @getCurrentPath()

      if active_path?
        if not @_grid_data.pathPartOfFilteredTree(active_path)
          @resetActivePath()

    @registerMetadataGenerator (item, ext, index) =>
      # Since we add and remove the filter related classes to the
      # row elements without passing through slick.grid, in case
      # of row invalidation, we need to let slick grid know the
      # row classes according to their filtered state
      grid_tree_filter_state = @_grid_data._grid_tree_filter_state

      if not grid_tree_filter_state? or not grid_tree_filter_state[index]?
        # If no filter active filter
        return {}

      return {cssClasses: @_getFilterStateClasses(grid_tree_filter_state[index])}

    waiting_rebuild = false
    filter_update_waiting = false
    updateFilterState = =>
      if not filter_update_waiting
        return

      if waiting_rebuild
        # During the time we are waiting for rebuild to complete
        # paths presented in the grid will be out of sync
        # with the new grid structure stored in @_grid_data.grid_tree,
        # therefore we'll have to wait for the rebuild to complete
        # in order to apply the filter represented in
        # @_grid_data._grid_tree_filter_state for the current @_grid_data.grid_tree
        @logger.debug "updateFilterState: blocked, waiting rebuild to complete"

        return

      filter_update_waiting = false

      # visible_tree_leaves_changes is an object of the form:
      #
      # {
      #   "collection_item_id": true
      # }
      #
      # The collection items ids reported by it are changes in the leaves of the
      # visible tree resulted from filter activation, deactivation and changes
      # to the tree resulted by an active filter. Its purpose is to provide a framework
      # that filter-aware descendants-sensitive fields can rely on to get indication for
      # when recalculation is required. Further, we try to provide this indication
      # in the most efficient way + the minimal amount of nodes that covers all the
      # updates requierd (leaves that got changed).
      #
      # It will include:
      #
      # When the filter becomes active: The leaves of the visible filtered tree,
      # that is, items that passed the filter and are either collapsed, have no
      # children, or have no descendants that passed the filter.
      # When the filter becomes deactivated: All the leaves of the visible tree,
      # that is, all the collapsed or leaf items.
      # When an active filter changes the visible tree:
      # * CONDITION_1 All the items that become hidden (leaves or not)
      # * CONDITION_2 All the new leaves of the visible filtered tree
      # * All the items that were leaves of the filtered tree (but not actual leaves
      #   of the real tree) that one of their descendants start passing the filter. DEPRECATED
      # * All the items that had were collapsed in the filtered tree, and all of
      #   their descendants stop passing the filter (item that becomes leaf of the
      #   filtered tree). DEPRECATED
      # * CONDITION_3 All the items which their collapsed-descendants filter-passing state changed.
      #
      #   Example: imagine a case where we had:
      #
      #   A
      #     B
      #       C
      #         D
      #
      #.    X
      #       Y
      #         D
      #
      #   A, X, Y Expanded.
      #   B is collapsed.
      #
      #   D changes it state from passing the filter to not passing the filter. B, and A that are in
      #   the visible tree, might have changes to their fields that are filter-aware and affected by
      #   their descendants.
      #
      #   The example demonstrates, that the fact that D pass the filter undex A,X,Y,D and is in the
      #   visible tree (and will be part of visible_tree_leaves_changes due to CONDITION_2) isn't enough
      #   to avoid checking all the potential paths that D is under, as B in this case need update
      #   as well.
      #
      #   Important Limitation of CONDITION_3:
      #
      #   We have limited support for recognition of CONDITION_3 for rows that are not representing
      #   collection items in the database.
      #
      #   As a result of change in the filter-passing state of items such as D in the example above,
      #   We need to find all the paths in which D is present. and to find the sub-paths that are
      #   leaves in the filter projected visible fields, to mark them as changed.
      #
      #   At the moment we don't supprt marking of leaves that aren't representing collection items.
      #   This is done for computational-complexity reasons (avoiding full tree scans that is required
      #   for real detection of all paths of an item in the fully expanded tree). And for the way
      #   that the visible_tree_leaves_changes is structured.
      #
      # Do not rely on the items to be leaves, in some cases, when distinguishing
      # leaves from non-leaves is too (computationaly) complex, we will send
      # items that their visibility state changed, that might have visible descendants.
      #
      # The object is sent as part of the data.visible_tree_leaves_changes of the
      # grid-tree-filter-updated event.
      #
      # It can be used by operation that maintain state of filter-aware fields,
      # that their values are affected by their filter-passing ≥descendants.
      visible_tree_leaves_changes = {}
      if not (grid_tree_filter_state = @_grid_data._grid_tree_filter_state)?
        @_previous_grid_data_filter_collection_items_ids = null

        @container.removeClass("filter-active")
        all_row_filter_state_classes_string = row_filter_state_classes.join " "
        @container.find(".slick-row").removeClass(all_row_filter_state_classes_string)

        for item, item_id in @_grid_data.grid_tree
          row_item_details = @_grid_data.grid_tree[item_id]
          collection_item_id = row_item_details[0]?._id

          if collection_item_id? and row_item_details[3] <= 0 # item is a collection item and is collapsed or has no children.
            visible_tree_leaves_changes[collection_item_id] = true
      else
        filter_init = false
        if not @container.hasClass("filter-active")
          filter_init = true # State changed from no filter to active filter

        for filter_state, item_id in grid_tree_filter_state
          $row = @_grid.getRowJqueryObj(item_id)
          row_item_details = @_grid_data.grid_tree[item_id]
          collection_item_id = row_item_details[0]?._id

          if filter_init
            if collection_item_id? and filter_state[2] == 1
              # When we activate the filter, mark all the *visible* filtered-tree leaves that represents
              # collection items as visible_tree_leaves_changes
              visible_tree_leaves_changes[collection_item_id] = true

          if $row?
            filter_state_classes =
              @_getFilterStateClasses(filter_state)

            non_filter_state_classes =
              _.difference row_filter_state_classes, filter_state_classes 

            if collection_item_id? and not filter_init
              # In consecutive filter changes after the first activation,
              # look for changes in the row visibility of collection items'
              # rows
              row_was_visible = isRowVisibleInFilterProjectedGrid($row)

            if not _.isEmpty filter_state_classes
              $row.addClass(filter_state_classes.join " ")
            if not _.isEmpty non_filter_state_classes
              $row.removeClass(non_filter_state_classes.join " ")

            if collection_item_id? and not filter_init
              row_is_visible = filter_state[0] > 0

              if row_is_visible != row_was_visible
                # Row visibility changed.

                # If visibility state changed ot hidden add to
                # visible_tree_leaves_changes
                #
                # XXX optimization note: we don't check whether the items was a leaf of the filtered
                # visible tree before, hence, in the case of visibility change to hidden,
                # we might get non-leaf added to visible_tree_leaves_changes
                # that can result in less efficient handling by the procedures that
                # reacts to these changes.
                if not row_is_visible
                  # CONDITION_1
                  visible_tree_leaves_changes[collection_item_id] = true
                else
                  # State changed to visible, add to the visible_tree_leaves_changes
                  # only if has no children, collapsed, or, if leaf of the visible tree (has
                  # no descendants that pass the filter.
                  #
                  # CONDITION_2
                  if row_item_details[3] != 1 or filter_state[0] == 3
                    visible_tree_leaves_changes[collection_item_id] = true

        if filter_init
          # Preperation for CONDITION_3 that will run in the next non-init run
          #
          @_previous_grid_data_filter_collection_items_ids = @_grid_data._filter_collection_items_ids
        else
          # CONDITION_3

          # Find diff of filter-passing collection items - this will give us both new items that pass
          # the filter, and items that got removed from the filter.
          new_passing_filter = {}
          stop_passing_filter = {}

          for item_id of @_previous_grid_data_filter_collection_items_ids
            if item_id not of @_grid_data._filter_collection_items_ids
              stop_passing_filter[item_id] = true

          for item_id of @_grid_data._filter_collection_items_ids
            if item_id not of @_previous_grid_data_filter_collection_items_ids
              new_passing_filter[item_id] = true

          addFilterPassingVisiblePathsOfItemIdToChanges = (item_id) =>
            # If not in the visible tree leaves changes already, and have indices in the non-filtered tree in its current collapsed state
            # check whether any of these indices, in the filtered tree is a leaf -> if it does, add item_id to
            # visible_tree_leaves_changes
            if not visible_tree_leaves_changes[item_id]? and (indices_in_grid_tree = @_grid_data._items_ids_map_to_grid_tree_indices[item_id])?
              # For first call, item_id for sure, 
              for index in indices_in_grid_tree
                if grid_tree_filter_state[index][2] == 1 # is leaf in the filter-projected tree
                  visible_tree_leaves_changes[item_id] = true

                  break

            # Find all the parents of item_id. Read CONDITION_3 doc above for why it is necessary
            # to check all the items.
            if (item_obj = @_grid_data.items_by_id[item_id])?
              # We might not have item_obj, if the parent isn't known to us, or if removed and
              # lingered in this task as parent.
              for parent_id of item_obj.parents
                if parent_id != "0"
                  addFilterPassingVisiblePathsOfItemIdToChanges(parent_id)

            return

          for changes_obj in [new_passing_filter, stop_passing_filter]
            for item_id of changes_obj
              # @_grid_data.getAllCollectionItemIdPaths() performs a full scan due to the GridData's Sections concepts
              # - we can't use it to determine whether or not an item, or one of its ancestors are in the
              # visible filtered tree.

              addFilterPassingVisiblePathsOfItemIdToChanges(item_id)              

          @_previous_grid_data_filter_collection_items_ids = @_grid_data._filter_collection_items_ids

        @container.addClass("filter-active")

      @emit "grid-tree-filter-updated", {visible_tree_leaves_changes: visible_tree_leaves_changes}

    @_grid_data.on "pre_rebuild", =>
      waiting_rebuild = true

    @on "rebuild_ready", =>
      waiting_rebuild = false

      updateFilterState()

    gridTreeFilterEventsHandler = =>
      filter_update_waiting = true

      updateFilterState()

    @once "init", =>
      @_grid_data.on "grid-tree-filter-cleared", gridTreeFilterEventsHandler
      @_grid_data.on "grid-tree-filter-updated", gridTreeFilterEventsHandler

      updateFilterState()

    @_initFiltersDom() # Implemented in filters_dom.coffee

  _getFilterStateClasses: (filter_state) ->
    classes = []

    [filter_state, special_position] = filter_state

    if special_position == 1 or special_position == 3
      classes.push "f-first"
    if special_position == 2 or special_position == 3
      classes.push "f-last"

    if filter_state == 2 or filter_state == 3
      classes.push "f-passed"

    if filter_state == 1 or filter_state == 2
      classes.push "f-inner-node"

    if filter_state == 3
      classes.push "f-leaf"

    return classes

  forceItemsPassCurrentFilter: (...args) ->
    # forceItemsPassCurrentFilter(item_id_1, item_id_2, ..., onReady)
    #
    # Items called as this method's args will pass the current filter
    # regardless their data.

    # onReady will be called after the grid processed the requested forced
    # items.

    @_grid_data.addFilterIndependentItems.apply(@_grid_data, args)

    return

  _updateFilterState: (force=false) ->

    # force allow recalculating @_columnsFilterStateToQuery()
    # when needed, even if the @_getViewFiltersState() didn't change
    # Example use: a filter that filters dates columns to show only
    # today's values - when date change we need to reproduce the
    # query for the new date, even though @_getViewFiltersState()
    # is the same.
    if force == false and JSON.sortify(new_state) == JSON.sortify(@_filters_state)
      @logger.debug "_updateFilterState: no change to filters state"

      return

    # Update filter according to the current view
    # emit "filter-change" if filter changed
    new_state = @_getViewFiltersState()

    @_filters_state = new_state

    @emit "filter-change", @_filters_state, @_columnsFilterStateToQuery()

    return

  _getViewFiltersState: (view) ->
    if not view?
      view = @getView()
    
    filters_state = _.object(_.filter(_.map(view, (column) -> [column.field, column.filter]), (filter_state) -> filter_state[1]?))

    if _.isEmpty filters_state
      return null

    return filters_state

  _columnsFilterStateToQuery: (columns_filters_state) ->
    if not columns_filters_state?
      columns_filters_state = @_filters_state

    if not columns_filters_state?
      return null

    current_columns_filters_queries = []

    extended_schema = @getSchemaExtendedWithCustomFields()
    for column_id, column_filter_state of columns_filters_state
      column_settings = extended_schema[column_id]
      filter_settings = column_settings.grid_column_filter_settings

      if not (filter_type = filter_settings?.type)?
        @logger.warn "column_id #{column_id} can't be filtered"

        continue

      filter_controller_constructor =
        PACK.filters_controllers[filter_type]

      if not (columnFilterStateToQuery = PACK.filters_types_state_to_query_transformations[filter_type])?
        @logger.warn "Couldn't find the columnFilterStateToQuery for filter type: #{filter_type}"

        return

      context =
        column_id: column_id
        grid_control: @
        column_schema_definition: column_settings
        column_filter_state_ops:
          getColumnFilter: => @getColumnFilter(column_id)
          setColumnFilter: (column_filter_state) => @setColumnFilter(column_id, column_filter_state)
          clearColumnFilter: => @clearColumnFilter(column_id)

      current_column_filter_query = columnFilterStateToQuery(column_filter_state, context)

      current_columns_filters_queries.push(current_column_filter_query)

    filter_query = null

    if current_columns_filters_queries.length == 0
      @logger.warn "_columnsFilterStateToQuery: filter is on, but no filters queries produced"

      filter_query = {}
    else if current_columns_filters_queries.length == 1
      filter_query = current_columns_filters_queries[0]
    else
      filter_query = {$and: current_columns_filters_queries}

    return filter_query

  clearColumnFilter: (column_id) -> @setColumnFilter(column_id, null)

  getColumnFilter: (column_id) ->
    for column_view in @getView()
      if column_view.field == column_id
        return column_view.filter

    @logger.warn "Couldn't find column_id filter. column_id #{column_id} is not present in the grid"

  setColumnFilter: (column_id, filter_state) ->
    # Replace the existing state
    view = @getView()

    for column_view in view
      if column_view.field == column_id
        column_view.filter = filter_state

        @setView view

        return

    @logger.warn "Filter didn't set. column_id #{column_id} is not present in the grid"

# Note, static method.
GridControl.installFilterType = (filter_type_id, definition) ->
  # Arguments:
  #
  # filtey_type_id: the type developers will use under the column schema's 
  # grid_column_filter_settings.type option to use this filter type.
  #
  # definition: an object of the form:
  #
  # {
  #   controller_constructor: Constructor
  #   column_filter_state_to_query: function
  # }
  #
  # ## controller_constructor
  #
  #   The controller constructor should be a constructor that initiates a
  #   property named @container with jquery html object for the content to
  #   show the user when the filter dialog is open.
  #
  #   The constructor gets two as its argument an object (named context) of the follow form:
  #   
  #   {
  #       grid_control: The current grid control obj
  #       column_settings: The settings of the target column
  #       column_filter_state_ops: {
  #         getColumnFilter(): returns the current column's filter state
  #         setColumnFilter(filter_state): a function that sets the column's filter state
  #           to the value given under filter_state replaces previous value. 
  #         clearColumnFilter: clears the current filter state (equiv. to setColumnFilter(null)).
  #       }
  #   }
  #
  #   filter_controller MUST define the prototype method: destroy()
  #   we will call this method when the controller need to be destroyed
  #
  # ## column_filter_state_to_query
  #
  #   The filter constructor uses the column_filter_state_ops to set the filter state
  #   the of the current column.
  #
  #   That state can be in any format or structure. The function provided for 
  #   column_filter_state_to_query should translate that structure to an actual
  #   mongo query, that will filter the tasks presented.
  #
  #   column_filter_state_to_query gets as its parameters: (column_filter_state, context)
  #
  #   column_filter_state is the current column's filter state as set by you earlier
  #     using column_filter_state_ops.setColumnFilter(state).
  #
  #   context: an object of the structure:
  #     {
  #       column_id: the current column id (as of writing, this is the field name, but might change in the future) 
  #       grid_control: the current grid control obj
  #       column_schema_definition: The simple schema definition of the main field of this
  #       column.
  #     }
  #
  #   column_filter_state_to_query should return the mongo query object you want to
  #   apply for the current filter state. That mongo query will be *merged* (not deep merge)
  #   with the other columns filters.
  #
  #   Note, you can return *any* query object you want, even one that affect other fields.

  PACK.filters_controllers[filter_type_id] = definition.controller_constructor
  PACK.filters_types_state_to_query_transformations[filter_type_id] = definition.column_filter_state_to_query

  return