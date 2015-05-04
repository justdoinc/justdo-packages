GridControl = (collection, container, operations_container) ->
  EventEmitter.call this

  @collection = collection
  @container = container
  @operations_container = $(operations_container)

  @_initialized = false
  @_destroyed = false

  @_grid_data = null
  @_grid = null

  @logger = Logger.get("grid-control")

  Meteor.defer =>
    @_init()

  if Tracker.currentComputation?
    Tracker.onInvalidate =>
      @destroy()

  return @

Util.inherits GridControl, EventEmitter

_.extend GridControl.prototype,
  _init: ->
    if @_initialized or @_destroyed
      return
    @_initialized = true

    @_load_formatters()
    @_load_editors()

    columns = @_buildColumns()

    options =
      enableColumnReorder: false
      editable: true
      autoEdit: true
      enableCellNavigation: true

    @_grid_data = new GridData @collection
    @_grid = new Slick.Grid @container, @_grid_data, columns, options

    #@_grid.setSelectionModel(new Slick.RowSelectionModel())

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

    @_grid_data.on "grid-item-changed", (row, fields) =>
      col_id_to_row = _.invert(_.map @_grid.getColumns(), (cell) -> cell.id)
      for field in fields
        @_grid.updateCell(row, parseInt(col_id_to_row[field], 10))

    @_grid_data.on "edit-failed", (err) =>
      console.log "edit-failed", err

    @_grid.onCellChange.subscribe (e, edit_req) =>
      @_grid_data.edit(edit_req)

    @emit "init"

  _buildColumns: ->
    columns = []

    columns.push
      id: "#",
      name: "",
      width: 10,
      selectable: false,
      resizable: false,
      cssClass: "cell-handle"
      focusable: false

    if @collection.simpleSchema?
      for field_id, definition of @collection.simpleSchema()._schema
        if not definition.grid_visible_column
          continue

        column = {id: field_id, field: field_id, name: definition.label}

        if definition.grid_insert_tree_controls
          column.formatter = @_formatters.TextWithTreeControls
          column.editor = @_editors.TextWithTreeControlsEditor

        if definition.grid_editable_column
          if not column.editor? # if not defined already
            column.editor = Slick.Editors.Text
        else
          column.focusable = false

        if definition.grid_default_width?
          column.width = definition.grid_default_width

        columns.push column
    else
      console.log "Warning: GridControl called for collection with no simpleSchema definition, can't init columns"

    columns

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
          
          @_grid.setActiveCell(row, 0)
      else
        row = @_grid_data.getItemRowByPath(path)

        @_grid.setActiveCell(row, 0)
    else
      @logger.error("Path `#{path}` doesn't exist")

  destroy: ->
    if @_destroyed
      return
    @_destroyed = true

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
