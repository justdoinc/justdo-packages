# Buffer added to fade speed to ensure animation completes before clearing search inputs
CONTEXT_MENU_FADE_BUFFER_MS = 50

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

      # When mouse enters submenu with search, clear any pending close timer
      $menu.on "mouseenter", ".dropdown-submenu", (e) ->
        if submenuCloseTimer
          Meteor.clearTimeout(submenuCloseTimer)
          submenuCloseTimer = null
        return

      # When mouse leaves submenu, protect if search input has content or is focused
      $menu.on "mouseleave", ".dropdown-submenu", (e) ->
        $submenu = $(e.currentTarget)
        submenuCloseTimer = Meteor.setTimeout ->
          if not $submenu.is(":hover")
            $submenu.removeClass("context-menu-hover-protection")
          return
        , 500
        return
      
      return

    # Clear search inputs and reset submenu when context menu completely closes
    # Use capture phase to run before context.js handler hides the menu
    clearSearchInputsHandler = (e) =>
      isMenuVisible = $(".dropdown-context").is(":visible")
      isClickInContextMenu = $(e.target).closest(".dropdown-context").length > 0
      
      # Only act if a context menu is visible and the click is outside the context menu entirely
      if isMenuVisible and not isClickInContextMenu
        # Wait for the fadeOut animation to complete before clearing search inputs
        Meteor.setTimeout =>
          $(".grid-columns-search-input").each (index, input) =>
            $input = $(input)
            if $input.val() isnt ""
              $input.val("")
              # Trigger a keyup event to reset the filter
              $input.trigger("keyup")
          return
        , context.CONSTANTS.FADE_SPEED_MS + CONTEXT_MENU_FADE_BUFFER_MS
      return
    
    # Remove any existing handler and add new one with capture phase
    document.removeEventListener("mousedown", clearSearchInputsHandler, true)
    document.addEventListener("mousedown", clearSearchInputsHandler, true)
    
    # Store reference for cleanup
    @_clearSearchInputsHandler = clearSearchInputsHandler

    setupColumnContextMenu = (type, additional_menu_items_arr) =>
      $(@_getColumnsManagerContextMenuSelector(type)).remove()
      
      grid_control_cmenu_target_selector = ".slick-header-column"
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

      $grid_control_cmenu_target.bind "mousedown", (e) ->
        return setColumnIndexOfLastOpenedCmenu(e)
      
      return

    hide_columns_to_the_right_menu_item =
      text: TAPi18n.__ "hide_columns_to_the_right_label"
      action: (e) =>
        @setView @getView().slice(0, column_index_of_last_opened_cmenu + 1)
        
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
        action: (e) =>
          @_hideFieldColumn(@getView()[column_index_of_last_opened_cmenu].field)
      }
    ]
    setupColumnContextMenu("last", hide_menu_item)
    # Add the "Hide Columns to the Right" menu item to the freeze/unfreeze column menu
    hide_menu_item.push(hide_columns_to_the_right_menu_item)
    # common columns context menu
    setupColumnContextMenu("common", hide_menu_item)

    # Handle right-click on empty space to the right of the last column header
    # For admins: show "Add Column" submenu + "Edit Custom Fields" option
    # For non-admins: show only "Add Column" submenu
    $headerColumns = $(".slick-header-columns", @container)
    
    # Create two separate context menus for the empty space:
    # one for admins (with Edit Custom Fields) and one for non-admins (without)
    emptySpaceAdminMenuId = @_getColumnsManagerContextMenuId("empty-space-admin")
    emptySpaceNonAdminMenuId = @_getColumnsManagerContextMenuId("empty-space-non-admin")
    $(@_getColumnsManagerContextMenuSelector("empty-space-admin")).remove()
    $(@_getColumnsManagerContextMenuSelector("empty-space-non-admin")).remove()
    
    # Admin menu: Add Column + Edit Custom Fields
    empty_space_admin_menu = append_fields_menu.concat([
      {
        text: TAPi18n.__ "edit_custom_fields_label"
        action: (e) =>
          APP.modules.project_page.project_config_ui.show()
      }
    ])
    
    # Non-admin menu: Add Column only
    empty_space_non_admin_menu = append_fields_menu.slice() # clone the array
    
    # Create both menus
    context.attach $headerColumns,
      id: emptySpaceAdminMenuId
      data: empty_space_admin_menu
    
    context.attach $headerColumns,
      id: emptySpaceNonAdminMenuId
      data: empty_space_non_admin_menu
    
    # Set up search functionality for both empty space menus
    for emptySpaceMenuType in ["empty-space-admin", "empty-space-non-admin"]
      setupSearchFunctionality(emptySpaceMenuType)
      setupAutoFocusOnSubmenuOpen(emptySpaceMenuType)
      setupSubmenuProtection(emptySpaceMenuType)
    
    # Helper function to show context menu at position
    # Uses constants from meteor-context-menu/lib/context.js for consistent positioning
    showContextMenuAtPosition = (menuId, e) =>
      $dd = $("#dropdown-" + menuId)
      if $dd.length > 0
        # Hide any other visible context menus
        $(".dropdown-context:not(.dropdown-context-sub)").hide()
        
        # Position and show the menu using context.CONSTANTS for consistency
        left = e.pageX
        if APP?.justdo_i18n?.isRtl()
          left = left - $dd.width() + context.CONSTANTS.HORIZONTAL_OFFSET
        else
          left -= context.CONSTANTS.HORIZONTAL_OFFSET
        
        autoH = $dd.height() + context.CONSTANTS.HEIGHT_BUFFER
        if (e.pageY + autoH) > $("html").height()
          $dd.addClass("dropdown-context-up").css({
            top: e.pageY - context.CONSTANTS.VERTICAL_OFFSET_ABOVE - autoH
            left: left
          }).fadeIn(context.CONSTANTS.FADE_SPEED_MS)
        else
          $dd.removeClass("dropdown-context-up").css({
            top: e.pageY + context.CONSTANTS.VERTICAL_OFFSET_BELOW
            left: left
          }).fadeIn(context.CONSTANTS.FADE_SPEED_MS)
    
    # Override the default contextmenu behavior for the header columns container
    $headerColumns.off("contextmenu").on "contextmenu", (e) =>
      # Only handle if clicking on empty space (not on a column header)
      if $(e.target).closest(".slick-header-column").length is 0
        e.preventDefault()
        e.stopPropagation()
        
        # Set the column index to the last column (for "Add Column" submenu)
        lastColumnIndex = @getView().length - 1
        setColumnIndexOfLastOpenedCmenu(e, lastColumnIndex)
        
        # Show appropriate menu based on admin status
        if JD?.active_justdo?.isAdmin?()
          showContextMenuAtPosition(emptySpaceAdminMenuId, e)
        else
          showContextMenuAtPosition(emptySpaceNonAdminMenuId, e)
      
      return

  _destroyColumnsManagerContextMenu: ->
    # Remove all column context menus
    for menuType in ["first", "last", "common", "empty-space-admin", "empty-space-non-admin"]
      $(@_getColumnsManagerContextMenuSelector(menuType)).remove()
    # Remove the empty space handler
    $(".slick-header-columns", @container).off "contextmenu"
    # Remove the document-level search clear handler
    if @_clearSearchInputsHandler
      document.removeEventListener("mousedown", @_clearSearchInputsHandler, true)