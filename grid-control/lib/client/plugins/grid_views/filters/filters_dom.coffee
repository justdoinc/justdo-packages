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
        <div class="dropdown-menu column-filter-dropdown border-0 shadow-lg"></div>
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
            $("""<div class="column-filter-button" id="#{column_settings.field}-filter-button" />""")

          do ($filter_control) =>
            # the context menu plugin blocks stops the propagation of the contextmenu
            # event, therefore we need to catch it here too
            $el.on "contextmenu", => @_closeFiltersDropdown()

            $filter_control
              .html("""<i class="fa fa-filter"></i>""")
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

    column_filter_button = $(".column-filter-button", @container)
    if not filters_state?
      column_filter_button.parent().removeClass("column-filter-active-wrapper")
      column_filter_button.parent().find(".slick-column-name").removeClass("bg-primary")
    else
      column_filter_button.each (i, el) =>
        $el = $(el)

        column_settings = $el.parent(".slick-header-column").data("column")
        column_id = column_settings.id

        if column_id of filters_state
          $el.parent().addClass("column-filter-active-wrapper")
          $el.parent().find(".slick-column-name").addClass("bg-primary")
        else
          $el.parent().removeClass("column-filter-active-wrapper")
          $el.parent().find(".slick-column-name").removeClass("bg-primary")

  _openFiltersDropdown: (element_type, $connected_element) ->
    @$filter_dropdown.data("open")(element_type, $connected_element)

  _closeFiltersDropdown: ->
    @$filter_dropdown.data("close")()

  _filtersDropdownOpenedHandler: ->
    column_settings = @$filter_dropdown.data("column-settings")
    column_id = column_settings.id

    if (filter_type = column_settings.filter_settings?.type)?
      if not (filter_type of PACK.filters_controllers)
        @_error "unknown-filter-type", "Can't open filter controller. Unknown filter type #{column_settings.filter_settings.type}"

        return

      controller_context =
        column_id: column_id
        grid_control: @
        column_settings: column_settings # AVOID USING THIS ONE. Use only column_schema_definition (column_settings isn't part of _columnsFilterStateToQuery output)
        column_schema_definition: @getSchemaExtendedWithCustomFields()?[column_id]
        column_filter_state_ops:
          getColumnFilter: => @getColumnFilter(column_id)
          setColumnFilter: (column_filter_state) => @setColumnFilter(column_id, column_filter_state)
          clearColumnFilter: => @clearColumnFilter(column_id)
      @_current_filter_controller =
        new PACK.filters_controllers[filter_type](controller_context)

      controller_container = $("""<div class="#{column_settings.filter_settings.type}-controller filter-controller-container" />""")
        .html(@_current_filter_controller.controller)

      dropdown_controls = """
        <div role="separator" class="dropdown-divider mt-0"></div>
        <div class="dropdown-filter-controls-container">
          <button type="button" class="btn btn-light border jd-btn-xsm close-dropdown">#{TAPi18n.__ "close"}</button>
          <button type="button" class="btn btn-light border jd-btn-xsm clear">#{TAPi18n.__ "clear"}</button>
      """

      if _.isFunction(PACK.filters_getSelectAllFilterState[filter_type])
        dropdown_controls += """
          <button type="button" class="btn btn-light border jd-btn-xsm all">#{TAPi18n.__ "all"}</button>
        """

      dropdown_controls += """
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

      $(".column-filter-dropdown .all", @$filter_dropdown).click =>
        @selectAllColumnFilters(column_settings.field)


      Meteor.defer =>
        # No clue why, but focusing on the same tick as the init tick messes up
        # with the positioning of the dropdown. (As of 2021-07-21 in Chrome). Daniel C.

        @_current_filter_controller.emit "insterted-to-dom"

        return

      return

  _filtersDropdownClosedHandler: ->
    @_grid_data.clearFilterIndependentItems()

    if @_current_filter_controller?
      @_current_filter_controller.destroy()

      @_current_filter_controller = null

  _updateFiltersDropdownPosition: ($connected_element) ->
    @$filter_dropdown
      .position
        of: $connected_element
        my: "#{APP.justdo_i18n.getRtlAwareDirection "left"} top"
        at: "#{APP.justdo_i18n.getRtlAwareDirection "left"} bottom"
        collision: "fit fit"

        using: (new_position, details) =>
          target = details.target
          element = details.element

          # Get the container position relative to screen
          container_position = 
            left: @container.offset().left
            right: @container.offset().left + @container.innerWidth()
          
          # Factor in also title column width because it's freezed, if the current dropdown isn't from title column
          field_id = target.element.parent().data "field_id"
          if field_id isnt "title"
            title_column_width = _.find(@getView(), (column) => column.field is "title")?.width or 0
            if APP.justdo_i18n.isRtl()
              container_position.right -= title_column_width
            else
              container_position.left += title_column_width

          target_position =
            left: target.left
            right: target.left + $connected_element.innerWidth()

          # If target position (filter icon) overflows the container, close the dropdown
          if (target_position.right > container_position.right) or (target_position.left < container_position.left)
            @_closeFiltersDropdown()

            return

          element.element.css
            top: new_position.top
            left: new_position.left

          return

    return
