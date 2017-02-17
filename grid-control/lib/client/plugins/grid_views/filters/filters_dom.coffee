PACK.filters_controllers = {}

_.extend GridControl.prototype,
  _initFiltersDom: ->
    @$filter_dropdown = null
    @_initFiltersDropdown()

    @_current_filter_controller = null

    @_setupColumnsFilters()

    @on "columns-headers-dom-rebuilt", =>
      @_setupColumnsFilters()

    @on "filter-change", =>
      @_updateFilterStateIndicator()

  _initFiltersDropdown: ->
    filter_dropdown_html = """
      <div class="dropdown column-filter-dropdown-container">
        <div class="dropdown-menu column-filter-dropdown"></div>
      </div>
    """

    @$filter_dropdown =
      @initGridBoundElement filter_dropdown_html,
        positionUpdateHandler: ($connected_element) =>
          @_updateFiltersDropdownPosition($connected_element)
        openedHandler: => @_filtersDropdownOpenedHandler()
        closedHandler: => @_filtersDropdownClosedHandler()

  _setupColumnsFilters: ->
    $(".slick-header-column", @container)
      .each (i, el) =>
        $el = $(el)

        column_settings = $el.data("column")

        if column_settings.filter_settings?
          $filter_control =
            $("<div class='column-filter-button' id='#{column_settings.field}-filter-button' />")

          do ($filter_control) =>
            # the context menu plugin blocks stops the propagation of the contextmenu
            # event, therefore we need to catch it here too
            $el.on 'contextmenu', => @_closeFiltersDropdown()

            $filter_control
              .html('<i class=\'fa fa-filter\'></i>')
              .mousedown (e) =>
                e.stopPropagation()
              .click (e) =>
                e.stopPropagation()

                @$filter_dropdown
                  .data("column-settings", column_settings)

                # we pass column_settings.field as the GridBoundElement type
                # so if same filter will be called again GridBoundElement will
                # toggle the dropdown for us
                @_openFiltersDropdown(column_settings.field, $filter_control) 

              .prependTo($el)

    @_updateFilterStateIndicator()

  _updateFilterStateIndicator: ->
    filters_state = @_getViewFiltersState()
    active_filter_class = "column-filter-active"

    column_filter_button = $(".column-filter-button", @container)
    if not filters_state?
      column_filter_button.removeClass(active_filter_class)
    else
      column_filter_button.each (i, el) =>
        $el = $(el)

        column_settings = $el.parent(".slick-header-column").data("column")
        column_id = column_settings.id

        if column_id of filters_state
          $el.addClass(active_filter_class)
        else
          $el.removeClass(active_filter_class)

  _openFiltersDropdown: (element_type, $connected_element) ->
    @$filter_dropdown.data("open")(element_type, $connected_element)

  _closeFiltersDropdown: ->
    @$filter_dropdown.data("close")()

  _filtersDropdownOpenedHandler: ->
    column_settings = @$filter_dropdown.data("column-settings")

    if column_settings.filter_settings?.type?
      if not (column_settings.filter_settings.type of PACK.filters_controllers)
        @_error "unknown-filter-type", "Can't open filter controller. Unknown filter type #{column_settings.filter_settings.type}"

        return
      
      @_current_filter_controller = new PACK.filters_controllers[column_settings.filter_settings.type](@, column_settings)

      controller_container = $("<div class='#{column_settings.filter_settings.type}-controller filter-controller-container' />")
        .html(@_current_filter_controller.controller)

      dropdown_controls = """
        <div role='separator' class='divider'></div>
        <div class="dropdown-filter-controls-container">
          <button type="button" class="btn btn-xs btn-default close-dropdown">Close</button>
          <button type="button" class="btn btn-xs btn-default clear">Clear</button>
          <div style="clear: both"></div>
        </div>
      """

      $(".column-filter-dropdown", @$filter_dropdown)
        .html(controller_container)
        .append(dropdown_controls)

      $(".column-filter-dropdown .close-dropdown", @$filter_dropdown).click =>
        @_closeFiltersDropdown()

      $(".column-filter-dropdown .clear", @$filter_dropdown).click =>
        @clearColumnFilter(column_settings.field)

  _filtersDropdownClosedHandler: ->
    @_grid_data.clearFilterIndependentItems()

    if @_current_filter_controller?
      @_current_filter_controller.destroy()

      @_current_filter_controller = null

  _updateFiltersDropdownPosition: ($connected_element) ->
    @$filter_dropdown
      .position
        of: $connected_element
        my: "left top"
        at: "left bottom"
        collision: "fit fit"
        using: (new_position, details) =>
          target = details.target
          element = details.element

          container_left_pos = @container.position().left
          container_right_pos = container_left_pos + @container.innerWidth()
          target_right = target.left + $connected_element.innerWidth()

          if target_right > container_right_pos or target.left < @container.position().left
            @_closeFiltersDropdown()

            return

          element.element.css
            top: new_position.top
            left: new_position.left
