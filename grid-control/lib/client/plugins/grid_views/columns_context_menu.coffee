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

    # Find missing fields
    current_view_fields = _.map @getView(), (col) -> col.field
    visible_fields = []
    for field, field_def of @schema
      if field_def.grid_visible_column
        visible_fields.push field
    missing_fields = _.filter visible_fields, (field) -> not(field in current_view_fields)

    append_fields_submenu = []
    for field in missing_fields
      do (field) =>
        append_fields_submenu.push
          text: @schema[field].label
          action: (e) =>
            view = @getView()
            # add field after clicked item
            view.splice(column_index_of_last_opened_cmenu + 1, 0, {field: field})

            @setView(view)

    append_fields_menu = [
      {
        text: 'Append Column'
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
      if e.which == 3
        column_index_of_last_opened_cmenu = 0

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
      if e.which == 3
        column_index_of_last_opened_cmenu = $(e.target).closest(".slick-header-column").index()


  _destroyColumnsManagerContextMenu: ->
    $(@_getColumnsManagerContextMenuSelector("first")).remove()
    $(@_getColumnsManagerContextMenuSelector("common")).remove()