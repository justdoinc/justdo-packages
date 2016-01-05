GridControl = (options, container, operations_container) ->
  EventEmitter.call this

  default_options =
    allow_dynamic_row_height: false

  @options = _.extend {}, default_options, options

  @collection = options.items_collection
  @container = container
  @operations_container = $(operations_container)

  @_initialized = false
  @_init_dfd = new $.Deferred() # resolved after init event emition; rejected if destroyed before init
  @initialized = new ReactiveVar false
  @_destroyed = false
  @_ready = false
  @ready = new ReactiveVar false

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

  @_operations_lock = new ReactiveVar false # Check /client/grid_operations/operations_lock.coffee
  @_operations_lock_timedout = new ReactiveVar false

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
    @initialized.set true

    @_load_formatters()
    @_load_editors()
    @_load_grid_operations()

    columns = @_getColumnsStructureFromView(@_init_view)

    slick_options =
      enableColumnReorder: false
      editable: true
      autoEdit: true
      enableCellNavigation: true

    if @options.allow_dynamic_row_height
      slick_options.dynamicRowHeight = true

    @_grid_data = new GridData @collection

    # proxy grid_data methods we want to be able to call from the
    # grid control level
    for method_name in PACK.grid_data_proxied_methods # defined in globals.js
      do (method_name) =>
        @[method_name] = -> @_grid_data[method_name].apply(@_grid_data, arguments)

    @_grid = new Slick.Grid @container, @_grid_data, columns, slick_options

    #@_grid.setSelectionModel(new Slick.RowSelectionModel())

    @_init_plugins()
    @_init_formatters()
    @_init_jquery_events()

    # emit path-changed only as a result of a real change.
    @current_path = new ReactiveVar @getActiveCellPath()

    @_grid.onActiveCellChanged.subscribe =>
      current_path = Tracker.nonreactive => @current_path.get()

      new_path = @getActiveCellPath()
      if new_path == current_path
        # Nothing changed
        return

      current_path = new_path
      @current_path.set(current_path)

      item_id = if current_path? then GridData.helpers.getPathItemId(current_path) else null

      @logger.debug "Path changed", current_path

      @emit "path-changed", current_path, item_id

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

      # XXX This was needed when the pre and post rebuild
      # operations weren't done on the same tick. Now that
      # they are (events in EventEmitter are actually synchronous)
      # there is nothing to protect from.
      # 
      # Reset the active cell
      #
      # This is important since during the build and until we finish the post
      # rebuild process below. The _grid_data.grid_tree will be in-consistent with
      # the slick grid structure.
      #
      # One example of buggy behavior that can be resulted from that: attempts to
      # get path for current active row using @_grid_data.getActiveCellPath
      # will result in wrong output
      # if active_cell_path?
      #   @_grid.resetActiveCell()

      @_grid_data.once "rebuild", (diff) =>
        # If first build, or if fixed row height is used, we can use @_grid.invalidate
        if not(@options.allow_dynamic_row_height) or not(@_ready)
          # Reload visible portion of the grid
          @_grid.invalidate()
        else
          current_row_offset = 0
          for change, i in diff
            [type, removed, added] = change

            if type == "same"
              current_row_offset += change[1] # we don't use "removed" to avoid confusion
            else
              callUpdateRowCount = false
              if i == diff.length - 1 or i == diff.length - 2
                # if this diff item is one before the last one, the next one
                # must be of type "same", therefore, we regard it as the last
                # update and callUpdateRowCount, read a comment in @_grid.spliceInvalidate
                # code for more details
                callUpdateRowCount = true

              @_grid.spliceInvalidate(current_row_offset, removed, added, callUpdateRowCount)

              current_row_offset += added

        # Restore cell state
        if active_cell_path?
          # If path doesn't exist any longer @activatePath will take
          # care of issuing a debug message.
          if cell_editor?
            # XXX note that since we lock flush when entering edit mode
            # this code will actually never happen.
            # (we lock flush to avoid the difficulty of bringing the editor
            # to the exact state it been in before flush, think of input pointer
            # etc.)
            entered_edit_mode = @editPathCell(active_cell_path, active_cell.cell, false)

            if entered_edit_mode and maintain_value?
              @_grid.getCellEditor().setValue(maintain_value)
          else
            @activatePath active_cell_path, active_cell.cell,
              expand: false
              scroll_into_view: false

        # tree_change, full_invalidation=true
        @logger.debug "Rebuild ready"
        @emit "rebuild_ready"
        @emit "tree_change", true

        if not @_ready
          @_ready = true
          @ready.set true
          @logger.debug "Ready"
          @emit "ready"

    @_grid_data.on "grid-item-changed", (row, fields) =>
      col_id_to_row = _.invert(_.map @_grid.getColumns(), (cell) -> cell.id)

      for field in fields
        cell_id = parseInt(col_id_to_row[field], 10)

        field_def = @schema[field]
        if field_def? and field_def.grid_effects_metadata_rendering
          @_grid.invalidateRow(row)
          @_grid.render()

          # no need to continue updating the rest of the cells, as we redraw
          # the entire row
          break

        @_grid.updateCell(row, cell_id)

      # tree_change, full_invalidation=false
      @emit "tree_change", false

    @_grid_data.on "edit-failed", (err) =>
      throw @_error "edit-failed", err

    @_grid.onCellChange.subscribe (e, edit_req) =>
      @_grid_data.edit(edit_req)

    @_grid.onBeforeEditCell.subscribe () =>
      # lock flushes while editing the cell
      @_grid_data._lock_flush()

      return true

    @_grid.onCellEditorDestroy.subscribe () =>
      @_grid_data._release_flush true

      return true

    for name, hook of @_init_hooks
      hook.call(@)

      @logger.debug("Init hook `#{name}` called")

    @emit "init"

    @_init_dfd.resolve()

  _error: (type, message, details) ->
    # XXX DRY, also appears in justdo-projects
    if _.isObject message
      details = message
      message = undefined 

    if not(type of @_errors_types)
      @logger.warn("Unknown error type: #{type}")
    else
      # Use default if type is known and no message provided
      if not message? or _.isEmpty(message)
        message = @_errors_types[type]

    log_message = "[#{type}] #{message}"
    if details?
      log_message += " #{JSON.stringify details}"

    @logger.error(log_message)

    new Meteor.Error(type, message, details)

  _loadSchema: ->
    schema = {}
    parents_found = false
    users_found = false
    first_visible_field_found = false

    err = (message) =>
      throw @_error "grid-control-schema-error", message

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

      # Init grid_values
      if def.grid_values?
        if _.isFunction(def.grid_values)
          def.grid_values = def.grid_values(@)
        else
          def.grid_values = _.extend({}, def.grid_values)

        for option_id, option of def.grid_values
          if not option.txt?
            err "Each value of grid_values must have a txt property"

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
      throw @_error "grid-control-invalid-view", message

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
      minWidth: 0
      width: 19,
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

      if field_def.grid_values?
        column.values = field_def.grid_values
      else
        column.values = null

      if column_def.grid_effects_metadata_rendering
        column.grid_effects_metadata_rendering = true

      if field_def.grid_column_filter_settings?
        column.filter_settings = field_def.grid_column_filter_settings

        if column_def.filter?
          column.filter_state = column_def.filter
        else
          column.filter_state = null

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

        # Uncomment for testing purpose to have filters active on load
        # if field_def.grid_column_filter_settings?
        #   field_view.filter = ["done"]

        view.push field_view

    return view

  setView: (view) ->
    @_validateView(view)

    columns = @_getColumnsStructureFromView view
    if not @_initialized
      @_init_view = columns
    else
      update_type = @_grid.setColumns columns

      if not update_type? # null means nothing changed
        return

      new_view = @getView()

      if update_type # true means dom rebuilt
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
          filter: column.filter_state
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

  activateRow: (row, cell = 0, scroll_into_view = true) ->
    @_grid.setActiveCell(row, cell, scroll_into_view)

  activatePath: (path, cell = 0, options) ->
    if not options?
      options = {}

    options = _.extend {expand: true, scroll_into_view: true}, options

    # If options.expand is set to false, don't expand path ancestors
    # in case path isn't visible due to collapsed ancestor/s,
    # in which case we'll avoid activation.

    # Return true if path activated successfuly, false otherwise
    path = GridData.helpers.normalizePath path

    path_parent = GridData.helpers.getParentPath path

    if @_grid_data.pathExist path
      # Expand parent path, if it isn't
      if not @_grid_data.isPathVisible(path)
        if not options.expand
          @logger.debug "activatePath: options.expand=false and path #{path} isn't visible due to collapsed ancestor - don't activate"

          return false
        else
          @_grid_data.expandPath(path_parent)

          @once "rebuild_ready", =>
            # post slick grid rebuild
            row = @_grid_data.getItemRowByPath(path)
            
            @activateRow(row, cell, options.scroll_into_view)
      else
        row = @_grid_data.getItemRowByPath(path)

        @activateRow(row, cell, options.scroll_into_view)
    else
      @logger.debug "activatePath: path `#{path}` doesn't exist"

      return false

    return true

  editPathCell: (path, cell, options) ->
    # Return true if entered into edit mode, false if failed
    activated = @activatePath(path, cell, options)

    if not activated
      return false

    @editActiveCell()
    return true

  editActiveCell: ->
    @_grid.editActiveCell()

  resetActivePath: (path) -> @_grid.resetActiveCell()

  registerMetadataGenerator: (cb) ->
    @_init_dfd.done =>
      # We need to wait for init to complete before we can call @_grid_data
      if @_grid_data.registerMetadataGenerator(cb)
        # if cb added successfully
        @_grid.invalidate()

  unregisterMetadataGenerator: (cb) ->
    @_init_dfd.done =>
      @_grid_data.unregisterMetadataGenerator(cb)
      @_grid.invalidate()

  #
  # Operations on active editor
  #
  saveAndExitActiveEditor: ->
    # Save current active editor and exit edit-mode
    # Does nothing if there's no active editor.

    # Returns true if commit succeed, false otherwise
    # (in the case of invalid content, for example).
    # If there is no active editor will return true.

    # If false returned - the editor is still active
    # and operations should continue accordingly. 
    return @_grid.getEditorLock().commitCurrentEdit()

  cancelAndExitActiveEditor: ->
    # Cancel current active editor and exit edit-mode
    # Does nothing if there's no active editor

    # Returns true always

    return @_grid.getEditorLock().cancelCurrentEdit()

  destroy: ->
    if @_destroyed
      return
    @_destroyed = true

    # In case init_dfd isn't resolved already, reject it
    @_init_dfd.reject()
    @initialized.set false
    @ready.set false

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

    @logger.debug "Destroyed"
