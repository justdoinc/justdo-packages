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
        label = APP.justdo_i18n.getI18nTextOrFallback {fallback_text: extended_schema[field].label, i18n_key: extended_schema[field].label_i18n}
        append_fields_submenu.push
          text: JustdoHelpers.xssGuard(label, {allow_html_parsing: true, enclosing_char: ''})
          action: (e) =>
            @addFieldToView(field, column_index_of_last_opened_cmenu + 1)

    append_fields_submenu = _.sortBy(append_fields_submenu, (i) -> i.text.toLowerCase())

    append_fields_menu = [
      {
        text: TAPi18n.__ "add_column_label"
        subMenu: append_fields_submenu
      }
    ]

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

    $(@_getColumnsManagerContextMenuSelector("first")).remove() 
    $grid_control_cmenu_target = $(".slick-header-column:first", @container)
    if append_fields_submenu.length > 0
      # context-menu for grid-control column
      context.attach $grid_control_cmenu_target,
        id: @_getColumnsManagerContextMenuId("first")
        data: append_fields_menu.concat freeze_unfreeze_column
    else
      context.attach $grid_control_cmenu_target,
        id: @_getColumnsManagerContextMenuId("first")
        data: [].concat freeze_unfreeze_column

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
          text: TAPi18n.__ "hide_column_label"
          action: (e) =>
            @_hideFieldColumn(@getView()[column_index_of_last_opened_cmenu].field)
        }
      ]

    $common_cmenu_target.bind "mousedown", (e) ->
      return setColumnIndexOfLastOpenedCmenu(e)

  _destroyColumnsManagerContextMenu: ->
    $(@_getColumnsManagerContextMenuSelector("first")).remove()
    $(@_getColumnsManagerContextMenuSelector("common")).remove()