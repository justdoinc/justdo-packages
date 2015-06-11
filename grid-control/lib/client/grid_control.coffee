GridControl = (collection, container, operations_container) ->
  EventEmitter.call this

  @collection = collection
  @container = container
  @operations_container = $(operations_container)

  @_initialized = false
  @_destroyed = false
  @_ready = false

  @_grid_data = null
  @_grid = null

  @logger = Logger.get("grid-control")

  @schema = null
  @grid_control_field = null
  @_loadSchema() # loads @schema and @grid_control_field

  # _init_view is the view we use when building slick grid for the
  # first time.
  # Calling @setView before init complete will change @_init_view value
  @_init_view = @_getDefaultView() # set @_init_view to the default view

  Meteor.defer =>
    @_init()

  if Tracker.currentComputation?
    Tracker.onInvalidate =>
      @destroy()

  return @

Util.inherits GridControl, EventEmitter

_.extend GridControl.prototype,
  # init hooks can be added by packages that extends grid-control features keys should
  # be the hooks human-readable names and the values functions that will be called with
  # the grid_control instance as this upon successful init (just before "init" event emittion).
  _init_hooks: {}

  _init: ->
    if @_initialized or @_destroyed
      return
    @_initialized = true

    @_load_formatters()
    @_load_editors()

    columns = @_getColumnsStructureFromView(@_init_view)

    options =
      enableColumnReorder: false
      editable: true
      autoEdit: true
      enableCellNavigation: true

    @_grid_data = new GridData @collection
    @_grid = new Slick.Grid @container, @_grid_data, columns, options

    #@_grid.setSelectionModel(new Slick.RowSelectionModel())

    @_init_plugins()
    @_init_formatters()
    @_init_jquery_events()
    @_init_operation_controllers()

    @_grid_data.on "pre_rebuild", =>
      # Keep information about active cell and whether or not in edit mode and
      # if yes editor value compared to stored value
      active_cell = @_grid.getActiveCell()
      active_cell_path = null
      if active_cell?
        active_cell_path = @_grid_data.getItemPath active_cell.row

      cell_editor = @_grid.getCellEditor()
      maintain_value = null
      if cell_editor?
        cell_editor_value = cell_editor.getValue()
        if cell_editor_value != @getCellStoredValue active_cell.row, active_cell.cell
          # keep current editor state if it's different from the stored value
          maintain_value = cell_editor_value
        @_grid.resetActiveCell()

      # post rebuild
      Meteor.defer =>
        # Reload visible portion of the grid
        @_grid.invalidate()

        # Restore cell state
        if active_cell_path?
          new_row = @_grid_data.getItemRowByPath active_cell_path

          if new_row == null
            @_grid.resetActiveCell()
          else
            @_grid.setActiveCell(new_row, active_cell.cell)

            if cell_editor?
              @_grid.editActiveCell()

              if maintain_value?
                @_grid.getCellEditor().setValue(maintain_value)

        if not @_ready
          @_ready = true
          @emit "ready"

        # tree_change, full_invalidation=true
        @emit "tree_change", true

    @_grid_data.on "grid-item-changed", (row, fields) =>
      col_id_to_row = _.invert(_.map @_grid.getColumns(), (cell) -> cell.id)

      for field in fields
        cell_id = parseInt(col_id_to_row[field], 10)
        column_def = @_grid.getColumns()[cell_id]

        if column_def? and column_def.grid_effects_metadata_rendering
          @_grid.invalidateRow(row)
          @_grid.render()

          # no need to continue updating the rest of the cells, as we redraw
          # the entire row
          break

        @_grid.updateCell(row, cell_id)

      # tree_change, full_invalidation=false
      @emit "tree_change", false

    @_grid_data.on "edit-failed", (err) =>
      console.log "edit-failed", err

    @_grid.onCellChange.subscribe (e, edit_req) =>
      @_grid_data.edit(edit_req)

    for name, hook of @_init_hooks
      hook.call(@)

      @logger.debug("Init hook `#{name}` called")

    @emit "init"

  _error: (type, message) ->
    @logger.error(message)

    throw new Meteor.Error(type, message)

  _loadSchema: ->
    schema = {}
    parents_found = false
    users_found = false
    first_visible_field_found = false

    err = (message) =>
      @_error "grid-control-schema-error", message

    set_default_formatter = (field_def, first_visible_field_formatter, other_visible_fields_formatter) =>
      if not field_def.grid_visible_column
        field_def.grid_column_formatter = null

        return

      if not field_def.grid_column_formatter?
        # If grid_column_formatter defined in the schema, do nothing
        if not first_visible_field_found
          # If this is the first field
          field_def.grid_column_formatter = first_visible_field_formatter
        else
          field_def.grid_column_formatter = other_visible_fields_formatter

    set_default_editor = (field_def, first_visible_field_editor, other_visible_fields_editor) =>
      if not field_def.grid_editable_column
        field_def.grid_column_editor = null

        return

      if not field_def.grid_column_editor?
        if not first_visible_field_found
          # If this is the first field
          field_def.grid_column_editor = first_visible_field_editor
        else
          field_def.grid_column_editor = other_visible_fields_editor

    if not @collection.simpleSchema()?
      err "GridControl called for a collection with no simpleSchema definition"

    for field_name, def of @collection.simpleSchema()._schema
      def = _.extend {}, def # Shallow copy definition

      if not def.label?
        def.label = field_name

      if field_name == "parents"
        # validate parents field
        if def.type != Object
          err("`parents` field must be of type Object")

        if not def.blackbox
          err("`parents` field must be blackboxed")

        if def.grid_visible_column
          err("`parents` field can't be visible")

        parents_found = true

      else if field_name == "users"
        if def.grid_visible_column
          err("`users` field can't be visible")

        users_found = true

      else
        if not def.grid_visible_column
          # When grid isn't visible, init relevant options values accordingly
          def.grid_editable_column = false
          def.grid_column_formatter = null
          def.grid_column_editor = null
          def.grid_default_grid_view = false
          def.grid_effects_metadata_rendering = false
        else
          # Set default formatter/editor according to field type
          if def.type is String
            set_default_formatter(def, "textWithTreeControls", "defaultFormatter")
            set_default_editor(def, "TextWithTreeControlsEditor", "TextEditor")
          if def.type is Date
            set_default_formatter(def, "textWithTreeControls", "unicodeDateFormatter")
            set_default_editor(def, "TextWithTreeControlsEditor", "UnicodeDateEditor")
          if def.type is Boolean
            set_default_formatter(def, "textWithTreeControls", "checkboxFormatter")
            set_default_editor(def, "TextWithTreeControlsEditor", "CheckboxEditor")
          else
            # For other types, same as String
            set_default_formatter(def, "textWithTreeControls", "defaultFormatter")
            set_default_editor(def, "TextWithTreeControlsEditor", "TextEditor")

          # Validate formatter/editor
          if not first_visible_field_found
            first_visible_field_found = true

            @grid_control_field = field_name

            # First visible field must be default field
            if not def.grid_default_grid_view
              err "As the first visible field, `#{field_name}` must have grid_default_grid_view option set to true"
            
            if not(def.grid_column_formatter in PACK.TreeControlFormatters)
              err "As the first visible field, `#{field_name}` must have grid_column_formatter option set to one of the grid-control formatter as set in PACK.TreeControlFormatters"
          else
            if def.grid_column_formatter in PACK.TreeControlFormatters
              err "`#{field_name}` is not the first visible field, it can't use `#{def.grid_column_formatter}` as its formatter as it's a grid-control formatter, as defined in PACK.TreeControlFormatters"

          if not(def.grid_column_formatter of PACK.Formatters)
            err "Field `#{field_name}` use an unknown formatter `#{def.grid_column_formatter}`"

          if def.grid_editable_column and not(def.grid_column_editor of PACK.Editors)
            err "Field `#{field_name}` use an unknown editor `#{def.grid_column_editor}`"

      schema[field_name] = def

    if not parents_found
      err "`parents` field is not defined in grid's schema"

    if not users_found
      err "`users` field is not defined in grid's schema"

    if not first_visible_field_found
      err "You need to set at least one visible field"

    @schema = schema

    return schema

  _validateView: (view) ->
    # Returns true if valid view, throws a "grid-control-invalid-view" error otherwise
    err = (message) =>
      @_error "grid-control-invalid-view", message

    if view.length == 0
      err "Provided view can't be empty, you must define at least one column"

    found_fields = {}
    first = true
    for column in view
      field_name = column.field

      if field_name of found_fields
        err "Provided view specified more than one column for the same field `#{field_name}`"
      found_fields[field_name] = true

      if not(field_name of @schema)
        err "Provided view has a column for an unknown field `#{field_name}`"

      field_def = @schema[field_name]
      if first
        if not (field_def.grid_column_formatter in PACK.TreeControlFormatters)
          err "Provided view must have as its first column a field with a tree-control formatter as defined in `PACK.TreeControlFormatters`"

        first = false
      else
        if field_def.grid_column_formatter in PACK.TreeControlFormatters
          err "Provided view can't have columns, other than the first one, for fields with a tree-control formatter as defined in `PACK.TreeControlFormatters`, see column for field `#{field_name}`"

      if not field_def.grid_visible_column
        err "Provided view has a column for non-visible field `#{field_name}`"        

    return true

  _getColumnsStructureFromView: (view) ->
    # This method assumes that the view passed to it passed @_validateView
    columns = []

    columns.push
      id: "#",
      name: "",
      width: 10,
      selectable: false,
      resizable: false,
      cssClass: "cell-handle"
      focusable: false

    for column_def in view
      field = column_def.field
      field_def = @schema[field]

      column =
        id: field,
        field: field,
        name: field_def.label
        # We know for sure that formatter exist for a column of view that passed validation
        # (only visible columns allowed, and formatter is assigned to them on @schema init
        # if they don't have on)
        formatter: @_formatters[field_def.grid_column_formatter]

      if field_def.grid_column_editor?
        column.editor = @_editors[field_def.grid_column_editor]
      else
        column.focusable = false

      if column_def.width?
        column.width = column_def.width
      else if field_def.grid_default_width?
        column.width = field_def.grid_default_width

      if column_def.grid_effects_metadata_rendering
        column.grid_effects_metadata_rendering = true

      columns.push column

    columns

  _getDefaultView: ->
    view = []

    for field_name, field_def of @schema # We assume @schema passed validation
      if field_def.grid_default_grid_view
        field_view =
          field: field_name,

        if field_def.grid_default_width?
          field_view.width = field_def.grid_default_width

        view.push field_view

    return view

  setView: (view) ->
    @_validateView(view)

    columns = @_getColumnsStructureFromView view
    if not @_initialized
      @_init_view = columns
    else
      @_grid.setColumns columns

      new_view = @getView()
      @emit "columns-headers-dom-rebuilt", new_view
      @emit "grid-view-change", new_view

  getView: () ->
    columns = @_grid.getColumns()

    view = _.map columns, (column) ->
      # If a column has no field we regard it as a misc column like the row handler
      if column.field?
        return {
          field: column.field
          width: column.width
        }

      return false

    view = _.filter view, (column) -> not(column is false)

    return view

  getCellField: (cell_id) -> @_grid.getColumns()[cell_id].field

  # Return the current value stored in the memory
  getCellStoredValue: (row, cell) -> @_grid_data.getItem(row)[@getCellField(cell)]

  getActiveCellItem: ->
    active_cell = @_grid.getActiveCell()

    if active_cell?
      return @_grid_data.getItem(active_cell.row)
    else
      return null

  getActiveCellPath: ->
    active_cell = @_grid.getActiveCell()

    if active_cell?
      return @_grid_data.getItemPath(active_cell.row)
    else
      return null

  activateRow: (row) ->
    @_grid.setActiveCell(row, 0)

  activatePath: (path) ->
    # Activate path, expand its parent if it isn't expanded.
    # Logs an error if path doesn't exist.
    path = GridData.helpers.normalizePath path

    path_parent = GridData.helpers.getParentPath path

    if @_grid_data.pathExist path
      # Expand parent path, if it isn't
      if not @_grid_data.getPathIsExpand(path_parent)     
        @_grid_data.expandPath(path_parent)
        @_grid_data._flush()

        Meteor.defer =>
          # post slick grid rebuild
          row = @_grid_data.getItemRowByPath(path)
          
          @activateRow(row)
      else
        row = @_grid_data.getItemRowByPath(path)

        @activateRow(row)
    else
      @logger.error("Path `#{path}` doesn't exist")

  destroy: ->
    if @_destroyed
      return
    @_destroyed = true

    @_destroy_plugins()
    @_destroy_jquery_events()

    if @_grid_data?
      @_grid_data.destroy()
      @_grid_data = null

    if @_grid?
      @_grid.destroy()
      @_grid = null

    if @_operation_controllers?
      for op_controller_name, op_controller of @_operation_controllers
        op_controller.destroy()

    @emit "destroyed"
