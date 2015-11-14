PACK.filters_controllers = {}

_.extend GridControl.prototype,
  _initFiltersDom: ->
    @$filter_dropdown = null
    @_initFiltersDropdown()

    @_current_filter_controller = null

    @_setupColumnsFilters()

    @on "columns-headers-dom-rebuilt", =>
      @_closeFiltersDropdown()
      @_setupColumnsFilters()

    @on "filter-change", =>
      @_updateFilterStateIndicator()

  _initFiltersDropdown: ->
    filter_dropdown_html = """
      <div class="dropdown column-filter-dropdown-container">
        <div class="dropdown-menu column-filter-dropdown"></div>
      </div>
    """

    @$filter_dropdown = $(filter_dropdown_html)

    @$filter_dropdown.appendTo("body")

    @$filter_dropdown.click (e) ->
      # Don't bubble clicks up, to avoid closing the dropdown
      e.stopPropagation()

    # The following proxies maintains @
    closeFiltersDropdownProxy = => @_closeFiltersDropdown()
    updateFiltersDropdownPositionProxy = => @_updateFiltersDropdownPosition()

    @_grid.onScroll.subscribe =>
      @_updateFiltersDropdownPosition()

    $(document).on 'click', closeFiltersDropdownProxy
    $(document).on 'contextmenu', closeFiltersDropdownProxy 
    $(window).on 'resize', updateFiltersDropdownPositionProxy
    $(window).on 'scroll', updateFiltersDropdownPositionProxy

    @_grid.onBeforeDestroy.subscribe =>
      $(document).off 'click', closeFiltersDropdownProxy
      $(document).off 'contextmenu', closeFiltersDropdownProxy 
      $(window).off 'resize', updateFiltersDropdownPositionProxy
      $(window).off 'scroll', updateFiltersDropdownPositionProxy

      @$filter_dropdown.remove()

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
              .click (e) =>
                e.stopPropagation()

                if @_isFiltersDropdownOpen() and
                   @$filter_dropdown.data("column-settings").field == column_settings.field
                    # If already open, toggle
                    @_closeFiltersDropdown()
                else
                  @$filter_dropdown
                    .data("column-settings", column_settings)
                    .data("connected-filter-button", $filter_control)

                  @_openFiltersDropdown()

                  @_updateFiltersDropdownPosition()

              .prependTo($el)

    @_updateFilterStateIndicator()

  _updateFilterStateIndicator: ->
    filters_state = @_getViewFiltersState()
    active_filter_class = "column-filter-active"

    if not filters_state?
      $(".column-filter-button").removeClass(active_filter_class)
    else
      $(".column-filter-button").each (i, el) =>
        $el = $(el)

        field = el.id.replace("-filter-button", "")

        if field of filters_state
          $el.addClass(active_filter_class)
        else
          $el.removeClass(active_filter_class)

  _isFiltersDropdownOpen: ->
    @$filter_dropdown.hasClass("open")

  _openFiltersDropdown: ->
    @_closeFiltersDropdown()

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

      $(".column-filter-dropdown .close-dropdown").click =>
        @_closeFiltersDropdown()

      $(".column-filter-dropdown .clear").click =>
        @clearFieldFilter(column_settings.field)

      @$filter_dropdown.addClass("open")

  _closeFiltersDropdown: ->
    if @$filter_dropdown?
      @$filter_dropdown.removeClass("open")

    if @_current_filter_controller?
      @_current_filter_controller.destroy()

      @_current_filter_controller = null

  _updateFiltersDropdownPosition: ->
    if @_isFiltersDropdownOpen()
      @$filter_dropdown
        .position
          of: @$filter_dropdown.data("connected-filter-button")
          my: "left top"
          at: "left bottom"
          collision: "fit fit"
          using: (new_position, details) =>
            target = details.target
            element = details.element

            # If filter button hidden close dropdown
            # XXX this calculation is wrong more work required in the future here
            # if (target.left + target.width >= window.innerWidth)
            #   @_closeFiltersDropdown()

            #   return

            element.element.css
              top: new_position.top
              left: new_position.left
