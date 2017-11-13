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

    append_fields_submenu = []
    extended_schema = @getSchemaExtendedWithCustomFields()
    for field in missing_fields
      do (field) =>
        append_fields_submenu.push
          text: extended_schema[field].label
          action: (e) =>
            @addFieldToView(field, column_index_of_last_opened_cmenu + 1)

    append_fields_menu = [
      {
        text: 'Add Column'
        subMenu: append_fields_submenu
      }
    ]

    $(@_getColumnsManagerContextMenuSelector("first")).remove() 
    $grid_control_cmenu_target = $(".slick-header-column:first", @container)
    if append_fields_submenu.length > 0
      # context-menu for grid-control column
      context.attach $grid_control_cmenu_target,
        id: @_getColumnsManagerContextMenuId("first")
        data: append_fields_menu
    else
      $grid_control_cmenu_target.bind "contextmenu", (e) ->
        e.preventDefault()

    $grid_control_cmenu_target.bind "mousedown", (e) ->
      return setColumnIndexOfLastOpenedCmenu(e, 0)

    # common columns context menu
    $common_cmenu_target = $('.slick-header-columns', @container).children().slice(1)
    $(@_getColumnsManagerContextMenuSelector("common")).remove()
    if append_fields_submenu.length > 0
      menu = append_fields_menu
    else
      menu = []
    context.attach $common_cmenu_target,
      id: @_getColumnsManagerContextMenuId("common")
      data: menu.concat [
        {
          text: 'Hide Column'
          action: (e) =>
            @_hideFieldColumn(@getView()[column_index_of_last_opened_cmenu].field)
        }
      ]

    $common_cmenu_target.bind "mousedown", (e) ->
      return setColumnIndexOfLastOpenedCmenu(e)

  _destroyColumnsManagerContextMenu: ->
    $(@_getColumnsManagerContextMenuSelector("first")).remove()
    $(@_getColumnsManagerContextMenuSelector("common")).remove()