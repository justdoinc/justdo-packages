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

  getColumnsContextMenuTargetSelector: ->
    return ".slick-header-column"

  _setupColumnsManagerContextMenu: ->
    # Store reference to this instance for use in event handlers
    grid_control = @
    init_context_menu()

    getColumnIndexFromGridColumnHeader = ($grid_column_header) ->
      val = $grid_column_header.index()

      return val

    # Find missing fields
    missing_fields = @fieldsMissingFromView()

    append_fields_menu = []

    if not _.isEmpty missing_fields
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
              action: (e, $grid_column_header) =>
                column_index = getColumnIndexFromGridColumnHeader($grid_column_header)
                grid_control.addFieldToView(field, column_index + 1)
        
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
          header: """<div class="grid-columns-search-container" style="position: relative; padding: 4px 8px;"><input type="text" class="grid-columns-search-input form-control form-control-sm border border-primary" placeholder="#{TAPi18n.__("search")}" style="padding-left: 28px; height: 28px;"><svg class="jd-icon text-secondary" style="position: absolute; top: 8px; left: 12px; height: 20px; width: 20px; pointer-events: none;"><use xlink:href="/layout/icons-feather-sprite.svg#search"></use></svg></div>"""
        }
        append_fields_submenu = [search_header_item].concat(append_fields_submenu)

      append_fields_menu.push
        text: TAPi18n.__ "add_column_label"
        subMenu: append_fields_submenu

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

    setupSubmenuProtection = (type) =>
      $menu = $(@_getColumnsManagerContextMenuSelector(type))
      
      if _.isEmpty $menu
        return

      submenuCloseTimer = null
      
      
      # When search input gains focus, keep submenu open
      $menu.on "focus", ".grid-columns-search-input", (e) ->
        $submenu = $(e.target).closest(".dropdown-submenu")
        $submenu.addClass("context-menu-hover-protection")
        
        # Clear any existing close timer
        if submenuCloseTimer
          Meteor.clearTimeout(submenuCloseTimer)
          submenuCloseTimer = null
        return

      # When mouse enters a submenu, clear any pending close timer for that submenu
      # and remove hover protection from OTHER submenus (to allow them to close)
      $menu.on "mouseenter", ".dropdown-submenu", (e) ->
        $entered_submenu = $(e.currentTarget)
        
        if submenuCloseTimer
          Meteor.clearTimeout(submenuCloseTimer)
          submenuCloseTimer = null
        
        # Remove hover protection from all OTHER submenus at the same level
        # This allows the "Add Column" submenu to close when "Expand level" is entered
        $menu.find(".dropdown-submenu").not($entered_submenu).removeClass("context-menu-hover-protection")
        return

      # When mouse leaves submenu, protect if search input has content or is focused
      $menu.on "mouseleave", ".dropdown-submenu", (e) ->
        $submenu = $(e.currentTarget)
        
        # Only apply delayed protection if this submenu contains the search input
        $search_input = $submenu.find(".grid-columns-search-input")
        if _.isEmpty $search_input
          # No search input in this submenu, remove protection immediately
          $submenu.removeClass("context-menu-hover-protection")
          return
        
        submenuCloseTimer = Meteor.setTimeout ->
          if not $submenu.is(":hover")
            $submenu.removeClass("context-menu-hover-protection")
          return
        , 500
        return
      
      return

    setupColumnContextMenu = (type, additional_menu_items_arr) =>
      $(@_getColumnsManagerContextMenuSelector(type)).remove()
      
      grid_control_cmenu_target_selector = grid_control.getColumnsContextMenuTargetSelector()
      if type is "first"
        grid_control_cmenu_target_selector = grid_control_cmenu_target_selector += ":first"
      else if type is "last"
        grid_control_cmenu_target_selector = grid_control_cmenu_target_selector += ":not(:first):last"
      else if type is "common"
        grid_control_cmenu_target_selector = grid_control_cmenu_target_selector += ":not(:first):not(:last)"

      $grid_control_cmenu_target = $(grid_control_cmenu_target_selector, @container)
      
      menu = append_fields_menu.concat(additional_menu_items_arr)
      
      context.attach $grid_control_cmenu_target,
        id: @_getColumnsManagerContextMenuId(type)
        data: menu

      setupSearchFunctionality(type)
      setupAutoFocusOnSubmenuOpen(type)
      setupSubmenuProtection(type)

      return

    hide_columns_to_the_right_menu_item =
      text: TAPi18n.__ "hide_columns_to_the_right_label"
      action: (e, $grid_column_header) =>
        column_index = getColumnIndexFromGridColumnHeader($grid_column_header)
        @setView @getView().slice(0, column_index + 1)
        
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
    if @getView().length > 1
      # Add the "Hide Columns to the Right" menu item to the freeze/unfreeze column menu only if there are more than one column
      freeze_unfreeze_column.push(hide_columns_to_the_right_menu_item) 
    setupColumnContextMenu("first", freeze_unfreeze_column)

    hide_menu_item = [
      {
        text: TAPi18n.__ "hide_column_label"
        action: (e, $grid_column_header) =>
          column_index = getColumnIndexFromGridColumnHeader($grid_column_header)
          @_hideFieldColumn(@getView()[column_index].field)
      }
    ]
    setupColumnContextMenu("last", hide_menu_item)
    # Add the "Hide Columns to the Right" menu item to the freeze/unfreeze column menu
    hide_menu_item.push(hide_columns_to_the_right_menu_item)
    # common columns context menu
    setupColumnContextMenu("common", hide_menu_item)

  _destroyColumnsManagerContextMenu: ->
    $(@_getColumnsManagerContextMenuSelector("first")).remove()
    $(@_getColumnsManagerContextMenuSelector("common")).remove()