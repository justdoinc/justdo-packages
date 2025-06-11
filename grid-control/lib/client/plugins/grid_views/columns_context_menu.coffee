init_context_menu = _.once ->
  # Note: seems that there is no issue with calling this one
  # more than once. So no worries if using context for other
  # things and re-initiating.
  context.init({})

_.extend GridControl.prototype,
  _hideFieldColumn: (field) ->
    if field == @grid_control_field
      throw @_error "wrong-argument", "Can't hide grid control field"

    @setView(_.filter(@getView(), (col) -> col.field != field))

  _getColumnsManagerContextMenuId: (type) ->
    # Current possible types: "first", "common"
    return "grid-control-#{type}-column-context-menu" + @getGridUid()

  _getColumnsManagerContextMenuSelector: (type) ->
    # Current possible types: "first", "common"
    return "#dropdown-" + @_getColumnsManagerContextMenuId(type)

  _setupColumnsManagerContextMenu: ->
    init_context_menu()

    column_index_of_last_opened_cmenu = null # excludes the handle from the count
    setColumnIndexOfLastOpenedCmenu = (e, val) ->
      # Checks whether event is mouse right click, and if so
      # sets column_index_of_last_opened_cmenu to val.
      # If val is not set, will try to find the column index
      # from the event.

      if e.which == 3 or
            (e.which == 1 and e.ctrlKey == true)
             # Under mac, users can open the context menu by clicking on the left
             # mouse key together with the ctrl key, on other systems, this won't
             # have any effect since the context menu won't be opened

        if not val?
          val = $(e.target).closest(".slick-header-column").index()

        column_index_of_last_opened_cmenu = val

      return

    # Find missing fields
    missing_fields = @fieldsMissingFromView()

    # Store reference to this instance for use in event handlers
    grid_control = @

    # Create search and filtering functions
    filterFieldsBySearch = (search_term) ->
      search_term = search_term.toLowerCase().trim()
      if _.isEmpty search_term
        return missing_fields
      search_term_regex = new RegExp(JustdoHelpers.escapeRegExp(search_term), "i")
      
      extended_schema = grid_control.getSchemaExtendedWithCustomFields()
      
      return _.filter missing_fields, (field) ->
        label = APP.justdo_i18n.getI18nTextOrFallback {
          fallback_text: extended_schema[field].label, 
          i18n_key: extended_schema[field].label_i18n
        }
        default_label = extended_schema[field].label
        # Consider a match if the search term is found in the label in the current language or the default language
        return search_term_regex.test(label) or search_term_regex.test(default_label)

    createFilteredSubmenuData = (filtered_fields) ->
      submenu = []
      extended_schema = grid_control.getSchemaExtendedWithCustomFields()
      
      for field in filtered_fields
        do (field) =>
          label = APP.justdo_i18n.getI18nTextOrFallback {
            fallback_text: extended_schema[field].label, 
            i18n_key: extended_schema[field].label_i18n
          }
          submenu.push
            text: JustdoHelpers.xssGuard(label, {allow_html_parsing: true, enclosing_char: ''})
            action: (e) =>
              grid_control.addFieldToView(field, column_index_of_last_opened_cmenu + 1)
      
      return JustdoHelpers.localeAwareSortCaseInsensitive submenu, (item) -> item.text.toLowerCase()

    # Initial filtered submenu with all fields
    initial_filtered_fields = filterFieldsBySearch("")
    append_fields_submenu = createFilteredSubmenuData(initial_filtered_fields)

    # Create the search header item for the submenu
    # IMPORTANT: Although it seems this block can be moved to the `createFilteredSubmenuData`,
    # it can't be done because `createFilteredSubmenuData` is also used in `refreshMenuItems`
    # to update the submenu items dynamically without re-creating the search header.
    if not _.isEmpty append_fields_submenu
      # Show search header if there are any fields to show
      search_header_item = {
        header: """<div class="grid-columns-search-container" style="position: relative; padding: 4px 8px;"><input type="text" class="grid-columns-search-input form-control form-control-sm" placeholder="#{TAPi18n.__("search")}" style="padding-left: 28px; height: 28px;"><svg class="jd-icon text-secondary" style="position: absolute; top: 8px; left: 12px; height: 20px; width: 20px; pointer-events: none;"><use xlink:href="/layout/icons-feather-sprite.svg#search"></use></svg></div>"""
      }
      append_fields_submenu = [search_header_item].concat(append_fields_submenu)

    append_fields_menu = [
      {
        text: TAPi18n.__ "add_column_label"
        subMenu: append_fields_submenu
      }
    ]

    # Add search functionality after the context menu is created
    # In other items we use `action` to handle click events, but here we need to handle the search input `keyup` events,
    # so we need to add the event listeners to the search input directly.
    setupSearchFunctionality = (type) =>
      $menu = $(@_getColumnsManagerContextMenuSelector(type))
      
      if _.isEmpty $menu
        return

      $searchInput = $menu.find(".grid-columns-search-input")
      
      if _.isEmpty $searchInput
        return
      
      refreshMenuItems = (e) ->
        e.stopPropagation()
        search_term = $(e.target).val()
        filtered_fields = filterFieldsBySearch(search_term)
        
        # Update the submenu items dynamically
        $submenu = $(e.target).closest(".dropdown-context-sub")
        $submenu.find("li:not(:first)").remove() # Remove all items except the search header
        
        # Add filtered items
        new_submenu = createFilteredSubmenuData(filtered_fields)
        # Call the `buildMenu` function to convert the submenu data to a jQuery object
        $new_submenu = context.buildMenu(new_submenu, grid_control._getColumnsManagerContextMenuId(type), true)
        # For each child item in the new submenu, append it to the existinhg submenu
        # We don't replace the entire submenu because we want to keep the search header
        $new_submenu.children().each (index, $item) ->
          $submenu.append($item)
        
        return
      
      $searchInput.off("keyup input", refreshMenuItems)
      $searchInput.on("keyup input", refreshMenuItems)
      
      return

    # Setup auto-focus functionality for the search input when submenu opens
    setupAutoFocusOnSubmenuOpen = (type) =>
      $menu = $(@_getColumnsManagerContextMenuSelector(type))
      
      if _.isEmpty $menu
        return

      # Find the "Add Column" submenu item
      $addColumnSubmenu = $menu.find(".dropdown-submenu").first()
      
      if _.isEmpty $addColumnSubmenu
        return
      
      # Use the existing mouseenter event from context.js to detect when submenu opens
      $addColumnSubmenu.off("mouseenter.grid-search-focus")
      $addColumnSubmenu.on "mouseenter.grid-search-focus", ->
        $searchInput = $addColumnSubmenu.find(".grid-columns-search-input")
        if not _.isEmpty $searchInput
          $searchInput.focus()
      
      return

    setupColumnContextMenu = (type, additional_menu_items_arr) =>
      $(@_getColumnsManagerContextMenuSelector(type)).remove()
      
      grid_control_cmenu_target_selector = ".slick-header-column"
      column_index_of_last_opened_cmenu = undefined
      if type is "first"
        grid_control_cmenu_target_selector = grid_control_cmenu_target_selector += ":first"
        column_index_of_last_opened_cmenu = 0
      else if type is "common"
        grid_control_cmenu_target_selector = grid_control_cmenu_target_selector += ":not(:first)"
      
      $grid_control_cmenu_target = $(grid_control_cmenu_target_selector, @container)
      menu = append_fields_menu.concat(additional_menu_items_arr)
      
      context.attach $grid_control_cmenu_target,
        id: @_getColumnsManagerContextMenuId(type)
        data: menu

      setupSearchFunctionality(type)
      setupAutoFocusOnSubmenuOpen(type)

      $grid_control_cmenu_target.bind "mousedown", (e) ->
        return setColumnIndexOfLastOpenedCmenu(e, column_index_of_last_opened_cmenu)
      
      return

    # At the moment we only support the first column freeze/unfreeze
    if @getView()[0].frozen is true
      freeze_unfreeze_column = [
        {
          text: TAPi18n.__ "unfreeze_column_label"
          action: (e) =>
            current_view = @getView()

            current_view[0].frozen = false

            @setView(current_view)

            return
        }
      ]
    else
      freeze_unfreeze_column = [
        {
          text: TAPi18n.__ "freeze_column_label"
          action: (e) =>
            current_view = @getView()

            current_view[0].frozen = true

            @setView(current_view)

            return
        }
      ]
    setupColumnContextMenu("first", freeze_unfreeze_column)

    hide_menu_item = [
      {
        text: TAPi18n.__ "hide_column_label"
        action: (e) =>
          @_hideFieldColumn(@getView()[column_index_of_last_opened_cmenu].field)
      }
    ]
    # common columns context menu
    setupColumnContextMenu("common", hide_menu_item)

  _destroyColumnsManagerContextMenu: ->
    $(@_getColumnsManagerContextMenuSelector("first")).remove()
    $(@_getColumnsManagerContextMenuSelector("common")).remove()