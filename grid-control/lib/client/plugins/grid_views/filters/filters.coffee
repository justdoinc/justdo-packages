row_filter_state_classes = ["f-first", "f-last", "f-passed", "f-leaf", "f-inner-node"]

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

      if not (grid_tree_filter_state = @_grid_data._grid_tree_filter_state)?
        @container.removeClass("filter-active")
        all_row_filter_state_classes_string = row_filter_state_classes.join " "
        @container.find(".slick-row").removeClass(all_row_filter_state_classes_string)
      else
        for filter_state, item_id in grid_tree_filter_state
          $row = @_grid.getRowJqueryObj(item_id)

          if $row?
            filter_state_classes =
              @_getFilterStateClasses(filter_state)

            non_filter_state_classes =
              _.difference row_filter_state_classes, filter_state_classes 

            if not _.isEmpty filter_state_classes
              $row.addClass(filter_state_classes.join " ")
            if not _.isEmpty non_filter_state_classes
              $row.removeClass(non_filter_state_classes.join " ")

          # console.log filter_state, item_id, filter_state_classes, non_filter_state_classes, $row

        @container.addClass("filter-active")

      @emit "grid-tree-filter-updated"

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

  forceItemsPassCurrentFilter: () ->
    # Items called as this method's args will pass the current filter
    # regardless their data.
    @_grid_data.addFilterIndependentItems.apply(@_grid_data, arguments)

  _updateFilterState: () ->
    # Update filter according to the current view
    # emit "filter-change" if filter changed
    new_state = @_getViewFiltersState()

    if JSON.sortify(new_state) == JSON.sortify(@_filters_state)
      @logger.debug "_updateFilterState: no change to filters state"

      return

    @_filters_state = new_state

    @emit "filter-change", @_filters_state, @_filterStateToFilterQuery()

  _getViewFiltersState: (view) ->
    if not view?
      view = @getView()
    
    filters_state = _.object(_.filter(_.map(view, (column) -> [column.field, column.filter]), (filter_state) -> filter_state[1]?))

    if _.isEmpty filters_state
      return null

    return filters_state

  _filterStateToFilterQuery: (filters_state) ->
    if not filters_state?
      filters_state = @_filters_state

    if not filters_state?
      return null

    filter_query = {}

    for field, state of filters_state
      filter_settings = @schema[field].grid_column_filter_settings

      if not filter_settings?.type?
        @logger.warn "Field #{filed} can't be filtered"
      
      filter_type = filter_settings.type

      if filter_type == "whitelist"
        filter_query[field] =
          $in: state
      else
        @logger.warn "No known mapping for filter_type #{filter_type} to grid-control filter query"

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

    @logger.warn "Filter didn't set. Field #{field} is not present in the grid"