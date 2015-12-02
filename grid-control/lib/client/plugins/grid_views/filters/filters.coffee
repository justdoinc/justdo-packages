row_filter_state_classes = ["f-first", "f-last", "f-passed", "f-leaf", "f-inner-node"]

_.extend GridControl.prototype,
  _initFilters: ->
    @_filters_state = null

    @once "init", =>
      # Load filters that exist before init.
      # Before init the grid-view-change won't call upon setView
      # so we need to check filters state for change
      @_updateFilterState()

    @on "grid-view-change", =>
      @_updateFilterState()

    @on "filter-change", (filter_state, filter_query) =>
      # Clear items that were forced to pass the previous filter
      @_grid_data.clearFilterIndependentItems()

      @_grid_data.filter.set filter_query

    @on "filtered-paths-updated", =>
      active_path = @getActiveCellPath()

      if active_path?
        if not @_grid_data.pathPassFilter(active_path)
          @resetActivePath()

    @registerMetadataGenerator (item, ext, index) =>
      # Since we add and remove the filter related classes to the
      # row elements without passing through slick.grid, in case
      # of row invalidation, we need to let slick grid know the
      # row classes according to their filtered state
      filter_paths = @_grid_data.getFilterPaths()

      if not filter_paths? or not filter_paths[index]?
        # If no filter active filter
        return {}

      return {cssClasses: @_getFilterStateClasses(filter_paths[index])}

    waiting_rebuild = false
    filter_update_waiting = false
    update_filtered_paths = =>
      if not filter_update_waiting
        return

      if waiting_rebuild
        # During the time we are waiting for rebuild to complete
        # paths presented in the grid will be out of sync
        # with the new grid structure stored in @_grid_data.grid_tree,
        # therefore we'll have to wait for the rebuild to complete
        # in order to apply the filter represented in
        # @_grid_data.getFilterPaths() for the current @_grid_data.grid_tree
        @logger.debug "update_filtered_paths: blocked, waiting rebuild to complete"

        return

      filter_update_waiting = false

      filter_paths = @_grid_data.getFilterPaths()

      if not filter_paths?
        @container.removeClass("filter-active")
      else
        for filter_state, item_id in filter_paths
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

      @emit "filtered-paths-updated"

    @_grid_data.on "pre_rebuild", =>
      waiting_rebuild = true

    @on "rebuild_ready", =>
      waiting_rebuild = false

      update_filtered_paths()

    filters_paths_events_handler = =>
      filter_update_waiting = true

      update_filtered_paths()

    @once "init", =>
      @_grid_data.on "filter-paths-cleared", filters_paths_events_handler
      @_grid_data.on "filter-paths-update", filters_paths_events_handler

      update_filtered_paths()

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

  clearFieldFilter: (field) -> @setFieldFilter(field, null)

  getFieldFilter: (field) ->
    for column_view in @getView()
      if column_view.field == field
        return column_view.filter

    @logger.warn "Couldn't find field filter. Field #{field} is not present in the grid"

  setFieldFilter: (field, filter_state) ->
    view = @getView()

    for column_view in view
      if column_view.field == field
        column_view.filter = filter_state

        @setView view

        return

    @logger.warn "Filter didn't set. Field #{field} is not present in the grid"
