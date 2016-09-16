GridControl = (options, container, operations_container) ->
  EventEmitter.call this

  default_options =
    grid_data_options: {}
    allow_dynamic_row_height: false
    usersDiffConfirmationCb: null
    items_types_settings: null

  @options = _.extend {}, default_options, options

  JustdoHelpers.loadEventEmitterHelperMethods(@)
  @loadEventsFromOptions() # loads @options.events, if exists

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
  @fixed_fields = null # will contain an array of the fields that can't be hidden or moved - in their order
  @_loadSchema() # loads @schema and @grid_control_field

  # _init_view is the view we use when building slick grid for the
  # first time.
  # Calling @setView before init complete will change @_init_view value
  @_init_view = @_getDefaultView() # set @_init_view to the default view

  @_operations_lock = new ReactiveVar false # Check /client/grid_operations/operations_lock.coffee
  @_operations_lock_timedout = new ReactiveVar false

  # During slick grid changes the active row gets cleared, and is being set
  # againg after the change is completed, if it is still in the tree.
  #
  # We rely on @_grid.onActiveCellChanged to track row changes, but during the
  # clear we will see the current row as null and we won't be able to say whether
  # it'll set to something else, or stay null.
  #
  # If following the null there'll be change to the current row or its path
  # we don't want resources that rely on them to invalidate, but the change
  # to null and back again will force that.
  #
  # Because of that we use intermediate computation to set @current_grid_tree_row
  # and @current_path, and rely on Meteor flush process to avoid their invalidation.
  @_current_state_invalidation_protection_computation = null
  @_current_grid_tree_row = new ReactiveVar null
  @_current_path = new ReactiveVar null
  @current_grid_tree_row = new ReactiveVar null
  @current_path = new ReactiveVar null

  @_states_classes_computations = null

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

    grid_data_options = _.extend {}, @options.grid_data_options,
      sections: @options.sections
      items_types_settings: @options.items_types_settings

    @_grid_data = new GridData @collection, grid_data_options

    # proxy grid_data methods we want to be able to call from the
    # grid control level
    for method_name in PACK.grid_data_proxied_methods # defined in globals.js
      do (method_name) =>
        @[method_name] = -> @_grid_data[method_name].apply(@_grid_data, arguments)

    @container.addClass "grid-control"

    @_grid = new Slick.Grid @container, @_grid_data, columns, slick_options

    @_initStatesClassesComputations()

    #@_grid.setSelectionModel(new Slick.RowSelectionModel())

    @_init_plugins()
    @_init_formatters()
    @_init_jquery_events()

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
      # get path for current active row using @_grid_data.getCurrentPathNonReactive
      # will result in wrong output
      # if active_cell_path?
      #   @_grid.resetActiveCell()

      @_grid_data.once "rebuild", (diff) =>
        # If first build, or if fixed row height is used, we can use @_grid.invalidate
        if not(@options.allow_dynamic_row_height)
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

        return

    @_grid_data.on "grid-item-changed", (row, fields) =>
      col_id_to_row = _.object(_.map @_grid.getColumns(), (cell, i) -> [cell.id, i])

      for field in fields
        field_def = @schema[field]
        if field_def? and field_def.grid_effects_metadata_rendering
          @_grid.invalidateRow(row)
          @_grid.render()

          # no need to continue updating the rest of the cells, as we redraw
          # the entire row
          break

        if col_id_to_row[field]?
          # Invalidate field column if in present grid
          @_grid.updateCell(row, col_id_to_row[field])

        if field_def.grid_dependent_fields?
          # Invalidate field dependent fields columns if exist and present in grid
          for dependent_field in field_def.grid_dependent_fields
            if col_id_to_row[dependent_field]?
              @_grid.updateCell(row, col_id_to_row[dependent_field])          

      # tree_change, full_invalidation=false
      @emit "tree_change", false

    @_grid_data.on "edit-failed", (err) =>
      throw @_error "edit-failed", err

    @_grid.onCellChange.subscribe (e, edit_req) =>
      @_grid_data.edit(edit_req)

    @_grid.onBeforeEditCell.subscribe =>
      # lock grid data while editing the cell
      @_grid_data._lock()

      return true

    @_grid.onCellEditorDestroy.subscribe =>
      @_grid_data?._release(true)

      return true

    @_current_state_invalidation_protection_computation = Tracker.autorun =>
      @current_grid_tree_row.set(@_current_grid_tree_row.get())
      @current_path.set(@_current_path.get())
    update_grid_position_tracking_reactive_vars = =>
      @_current_grid_tree_row.set(@getCurrentRowNonReactive())
      @_current_path.set(@getCurrentPathNonReactive())
    update_grid_position_tracking_reactive_vars() # init the vars
    @_grid.onActiveCellChanged.subscribe update_grid_position_tracking_reactive_vars

    for name, hook of @_init_hooks
      hook.call(@)

      @logger.debug("Init hook `#{name}` called")

    @_initialized = true
    @initialized.set true
    @emit "init"

    @_init_dfd.resolve()

  _error: JustdoHelpers.constructor_error

  _initStatesClassesComputations: ->
    @_states_classes_computations = []

    addPrefix = (state_name) -> "slick-state-#{state_name}"

    # grid not-ready state
    @_states_classes_computations.push Tracker.autorun =>
      state_name = addPrefix("not-ready")

      if not @ready.get()
        @container.addClass state_name
      else
        @container.removeClass state_name

    # operations lock active
    @_states_classes_computations.push Tracker.autorun =>
      state_name = addPrefix("ops-lock")

      if @operationsLocked()
        @container.addClass state_name
      else
        @container.removeClass state_name

  _destroyStatesClassesComputations: ->
    if @_states_classes_computations?    
      for comp in @_states_classes_computations
        comp.stop()

  _loadSchema: ->
    schema = {}
    fixed_fields = []
    parents_found = false
    users_found = false
    grid_control_field_found = false

    err = (message) =>
      throw @_error "grid-control-schema-error", message

    set_default_formatter = (field_def, grid_control_field_formatter, other_visible_fields_formatter) =>
      if not field_def.grid_visible_column
        field_def.grid_column_formatter = null

        return

      if not field_def.grid_column_formatter?
        # If grid_column_formatter defined in the schema, do nothing
        if not grid_control_field_found and not field_def.grid_pre_grid_control_column
          # If this is the grid control field
          field_def.grid_column_formatter = grid_control_field_formatter
        else
          field_def.grid_column_formatter = other_visible_fields_formatter

    set_default_editor = (field_def, grid_control_field_editor, other_visible_fields_editor) =>
      if not field_def.grid_editable_column
        field_def.grid_column_editor = null

        return

      if not field_def.grid_column_editor?
        if not grid_control_field_found and not field_def.grid_pre_grid_control_column
          # If this is the grid control field
          field_def.grid_column_editor = grid_control_field_editor
        else
          field_def.grid_column_editor = other_visible_fields_editor

    if not @collection.simpleSchema()?
      err "GridControl called for a collection with no simpleSchema definition"

    for field_name, def of @collection.simpleSchema()._schema
      def = _.extend {}, def # Shallow copy definition

      if not def.label?
        def.label = field_name

      if field_name == "users"
        users_found = true

      if field_name == "parents"
        # validate parents field
        if def.type != Object
          err("`parents` field must be of type Object")

        if not def.blackbox
          err("`parents` field must be blackboxed")

        if def.grid_visible_column
          err("`parents` field can't be visible")

        parents_found = true

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

          # Validate formatter/editor and build fixed_fields
          if not grid_control_field_found and not def.grid_pre_grid_control_column
            grid_control_field_found = true
            fixed_fields.push field_name

            @grid_control_field = field_name

            # grid control field must be a default field
            if not def.grid_default_grid_view
              err "As the grid control field, `#{field_name}` must have grid_default_grid_view option set to true"
            
            if not(def.grid_column_formatter in PACK.TreeControlFormatters)
              err "As the grid control field, `#{field_name}` must have grid_column_formatter option set to one of the grid-control formatter as set in PACK.TreeControlFormatters"
          else
            if def.grid_column_formatter in PACK.TreeControlFormatters
              err "`#{field_name}` is not the grid control field, it can't use `#{def.grid_column_formatter}` as its formatter as it's a grid-control formatter, as defined in PACK.TreeControlFormatters"

            # grid_pre_grid_control_column related schema updates
            if grid_control_field_found and def.grid_pre_grid_control_column
              # Ignore grid_pre_grid_control_column if grid_control_field_found already
              delete def.grid_pre_grid_control_column
            else if not grid_control_field_found and def.grid_pre_grid_control_column
              # Mark as a fixed field
              fixed_fields.push field_name

              # Force grid_pre_grid_control_column to be visible
              def.grid_default_grid_view = true

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

    if not grid_control_field_found
      err "You need to set at least one visible field without the grid_pre_grid_control_column option set to true"

    # Add to each field information about the fields that depend on it under the "grid_dependent_fields" property
    for dependent_field_name, dependent_field_def of schema
      if _.isArray (dependencies = dependent_field_def.grid_dependencies_fields)
        for dependency_name in dependencies
          if (dependency_def = schema[dependency_name])?
            if not dependency_def.grid_dependent_fields?
              dependency_def.grid_dependent_fields = []

            dependency_def.grid_dependent_fields.push(dependent_field_name)

    @fixed_fields = fixed_fields
    @schema = schema

    return schema

  _validateView: (view) ->
    # Returns true if valid view, throws a "grid-control-invalid-view" error otherwise
    err = (message) =>
      throw @_error "grid-control-invalid-view", message

    if view.length < @fixed_fields.length
      err "View must include all fixed fields #{JSON.stringify(@fixed_fields)}"

    found_fields = {}

    fixed_fields = @fixed_fields.slice() # copy

    for column in view      
      field_name = column.field

      if (current_fixed_field = fixed_fields.shift())? and current_fixed_field != field_name
        err "View must include all the fixed fields in their order - couldn't find #{current_fixed_field}"

      if field_name of found_fields
        err "Provided view specified more than one column for the same field `#{field_name}`"
      found_fields[field_name] = true

      if not(field_name of @schema)
        err "Provided view has a column for an unknown field `#{field_name}`"

      field_def = @schema[field_name]
      if not field_def.grid_visible_column
        err "Provided view has a column for non-visible field `#{field_name}`"        

    return true

  _getColumnsStructureFromView: (view) ->
    # This method assumes that the view passed to it passed @_validateView
    columns = []

    first = true
    for column_def in view
      field = column_def.field
      field_def = @schema[field]

      label = field_def.label
      if first
        first = false
        label = "<div class='slick-loading-indicator'></div>#{label}"

      column =
        id: field,
        field: field,
        name: label
        # We know for sure that formatter exist for a column of view that passed validation
        # (only visible columns allowed, and formatter is assigned to them on @schema init
        # if they don't have on)
        formatter: @_formatters[field_def.grid_column_formatter]

      if field_def.grid_column_editor?
        column.editor = @_editors[field_def.grid_column_editor]
      else
        column.focusable = false

      if field not in @fixed_fields
        column.reorderable = true

      if column_def.width?
        column.width = column_def.width
      else if field_def.grid_default_width?
        column.width = field_def.grid_default_width

      if field_def.grid_fixed_size_column? and field_def.grid_fixed_size_column
        column.resizable = false
        column.minWidth = 0

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

  getView: ->
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

  #
  # Events
  #
  eventCellIsActiveCell: (e) ->
    # e is the event object
    event_cell = @_grid.getCellFromEvent(e)

    if not event_cell?
      return false

    event_row = event_cell.row
    event_cell = event_cell.cell

    active_cell = @_grid.getActiveCell()

    if not active_cell?
      return false

    active_row = active_cell.row
    active_cell = active_cell.cell

    if event_row == active_row and event_cell == active_cell
      return true

    return false

  getEventItem: (e) ->
    if not (cell = @_grid.getCellFromEvent(e))?
      return null

    return @_grid_data.getItem(cell.row)

  getEventPath: (e) ->
    if not (cell = @_grid.getCellFromEvent(e))?
      return null

    return @_grid_data.getItemPath(cell.row)

  #
  # Current row
  #
  getCurrentRowNonReactive: -> @_grid.getActiveCell()?.row
  getCurrentRow: ->
    # We let @current_grid_tree_row trigger reactivity, but we always return
    # the real active cell by checking @_grid.getActiveCell() directly.
    #
    # Read more about @current_grid_tree_row above.
    @current_grid_tree_row.get()

    return @getCurrentRowNonReactive()

  #
  # Current Path
  #
  getCurrentPathNonReactive: ->
    if (active_cell_row = @getCurrentRowNonReactive())?
      return @_grid_data.getItemPath(active_cell_row)

    return null

  getCurrentPath: ->
    # We let @current_path trigger reactivity, but we always return
    # the real active path by checking @_grid.getCurrentRowNonReactive() directly.
    #
    # Read more about @current_path above.
    @current_path.get()

    return @getCurrentPathNonReactive()

  #
  # Row grid tree details
  #

  # getRowGridTreeDetailsNonReactive:
  #   Non reactive version at the moment, when implement the reactive version
  #   consider the need to manage invalidations as a result of details changes,
  #   just as we do in the special case of @getCurrentPathObj()
  getRowGridTreeDetailsNonReactive: (row) ->
    if not row?
      return null
    
    return @_grid_data.grid_tree[row]

  getCurrentRowGridTreeDetailsNonReactive: ->
    if not (row = @getCurrentRowNonReactive())?
      return null

    return @getRowGridTreeDetailsNonReactive(row)

  #
  # Path grid tree details
  #
  getPathObjNonReactive: (path) ->
    if not (row = @_grid_data.getPathGridTreeIndex(path))?
      return null

    return @_grid_data.getItem(row)

  getCurrentPathObjNonReactive: ->
    # We don't give an option to filter fields for the non reactive getter
    # as the only real reason to have it for the reactive one is to allow
    # controlling which field changes should trigger invalidation
    if not (active_item_details = @getCurrentRowGridTreeDetailsNonReactive())?
      return null

    return active_item_details[0]

  getCurrentPathObj: (fields) ->
    # Reactive to:
    #   * Path changes
    #   * Changes to the active item obj (if fields specified only, changes
    #     to these fields will trigger reactivity).
    #     Important Note: that for items that are stored in a Mongo
    #     collection, only once the data changes are recognised and
    #     handled by the grid's internal data structures activeItemObj
    #     reactivity will trigger.
    #     activeItemObj is always consistent with the grid's internal
    #     data structures, which, on occasions such as flush blocks,
    #     might be different from the data in the mongo collection.

    if not (current_path = @getCurrentPath())?
      # We call @getCurrentPath() only to make current_path reactivity
       # dependency
      return null

    if not fields?
      fields = {}

    fieldsProjection = LocalCollection._compileProjection(fields) # LocalCollection Comes from minimongo

    _getActiveItemObj = =>
      if not (active_item_obj = @getCurrentPathObjNonReactive())?
        return null

      if active_item_obj._type?
        # fieldsProjection doesn't work well with multi-layer object, looking only
        # on the first layer.
        # In typed items we have multi layer objects (which we depend on for data
        # consistency in some situations).
        # So, for typed items, we send to fieldsProjection only the data layer of
        # typed items.
        #
        # Note that this is also critical for the jsonComp we do in later in this
        # func
        active_item_obj = Object.getPrototypeOf(active_item_obj)

      return fieldsProjection(active_item_obj)

    current_obj = _getActiveItemObj()
    if not (current_computation = Tracker.currentComputation)?
      # If reactivity not required (no active comp), just return the value
      return current_obj

    _invalidateOnActiveItemObjChanged = ->
      if not JustdoHelpers.jsonComp(current_obj, _getActiveItemObj())
        current_computation.invalidate()

      return

    @on "tree_change", _invalidateOnActiveItemObjChanged
    Tracker.onInvalidate =>
      @off "tree_change", _invalidateOnActiveItemObjChanged

    return current_obj

  #
  # activate row/path
  #
  activateRow: (row, cell = 0, scroll_into_view = true) ->
    @_grid.setActiveCell(row, cell, scroll_into_view)

  activatePath: (path, cell=0, options) ->
    if not options?
      options = {}

    options = _.extend {expand: true, scroll_into_view: true}, options

    # If options.expand is set to false, don't expand path ancestors
    # in case path isn't visible due to collapsed ancestor/s,
    # in which case we'll avoid activation.

    # Return true if path activated successfuly, false otherwise
    path = GridData.helpers.normalizePath path

    path_parent = GridData.helpers.getParentPath path

    # XXX pathExist isn't filters aware, therefore we might open the path
    # ancestor even though the path is actually filtered
    if @_grid_data.pathExist path
      # Expand parent path, if it isn't
      if not @_grid_data.pathInGridTree(path)
        if not options.expand
          @logger.debug "activatePath: options.expand=false and path #{path} isn't visible due to collapsed ancestor - don't activate"

          return false
        else
          @_grid_data.expandPath path_parent

          @once "rebuild_ready", =>
            # post slick grid rebuild
            row = @_grid_data.getPathGridTreeIndex(path)

            if row?
              @activateRow(row, cell, options.scroll_into_view)
      else
        row = @_grid_data.getPathGridTreeIndex(path)

        @activateRow(row, cell, options.scroll_into_view)
    else
      @logger.debug "activatePath: path `#{path}` doesn't exist"

      return false

    return true

  activateCollectionItemId: (item_id, cell = 0, options) ->
    @activatePath(@_grid_data.getCollectionItemIdPath(item_id), cell, options)

  movePath: (path, new_location, cb, usersDiffConfirmationCb) ->
    # A proxy to grid-data's movePath that takes care of using
    # options.usersDiffConfirmationCb if no custom
    # usersDiffConfirmationCb provided above

    if not usersDiffConfirmationCb?
      usersDiffConfirmationCb = @options.usersDiffConfirmationCb

    if _.isFunction usersDiffConfirmationCb
      # if there's usersDiffConfirmationCb prevent operations lock
      # expiration timeout while waiting for confirm/cancel.
      # We do that since the provided usersDiffConfirmationCb
      # might wait for user input.
      wrappedUsersDiffConfirmationCb = (item_id, target_id, diff, confirm, cancel) =>
        @_preventOperationsLockExpiration (releaseExpirationLock) =>
          wrappedConfirm = =>
            releaseExpirationLock()

            confirm()

          wrappedCancel = =>
            releaseExpirationLock()

            cancel()

          usersDiffConfirmationCb item_id, target_id, diff, wrappedConfirm, wrappedCancel

    return @_grid_data.movePath(path, new_location, cb, wrappedUsersDiffConfirmationCb)

  editPathCell: (path, cell, options) ->
    # Return true if entered into edit mode, false if failed
    activated = @activatePath(path, cell, options)

    if not activated
      return false

    @editActiveCell()
    return true

  editActiveCell: ->
    @_grid.editActiveCell()

  resetActivePath: -> @_grid.resetActiveCell()

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

    if @_current_state_invalidation_protection_computation?
      @_current_state_invalidation_protection_computation.stop()

    @_destroyStatesClassesComputations()
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
