init_context_menu = _.once ->
  context.init({})

_.extend GridControl.prototype,
  _hideFieldColumn: (field) ->
    if field == @grid_control_field
      throw @_error "wrong-argument", "Can't hide grid control field"

    @setView(_.filter(@getView(), (col) -> col.field != field))

  _setupColumnsManagerContextMenu: () ->
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

    grid_control_cmenu_id = "grid-control-column-context-menu"
    $grid_control_cmenu_target = $(".slick-header-column:first")
    $("#dropdown-#{grid_control_cmenu_id}").remove() 
    if append_fields_submenu.length > 0
      # context-menu for grid-control column
      context.attach $grid_control_cmenu_target,
        id: grid_control_cmenu_id
        data: append_fields_menu
    else
      $grid_control_cmenu_target.bind "contextmenu", (e) ->
        e.preventDefault()

    $grid_control_cmenu_target.bind "mousedown", (e) ->
      if e.which == 3
        column_index_of_last_opened_cmenu = 0

    # common columns context menu
    $('#dropdown-common-column-context-menu').remove()
    $common_cmenu_target = $('.slick-header-columns').children().slice(1)
    if append_fields_submenu.length > 0
      menu = append_fields_menu
    else
      menu = []
    context.attach $common_cmenu_target,
      id: 'common-column-context-menu'
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