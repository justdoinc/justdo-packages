GridControl = (options, container, operations_container) ->
  EventEmitter.call this

  default_options =
    grid_data_options: {}
    allow_dynamic_row_height: false
    usersDiffConfirmationCb: null
    items_types_settings: null
    default_view_extra_fields: null # if set to array of fields names
                                    # these fields will be appended
                                    # to the default view on init
    forced_metadata_affecting_fields: null # Can be set to an object of the form: {field: true}
                                           # Changes to field will trigger row invalidations
                                           # regardless on its schema's grid_effects_metadata_rendering
                                           # setting
    preInit: -> return

  # Different number than @getGridUid(), it uses for ops that are necessary pre-grid-init
  # (before the grid init @getGridUid() will return null)
  @grid_control_uid = Random.id()

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

  @_on_destroy_procedures = []

  @custom_fields_manager = null
  @custom_fields_changes_computation = null
  if @options.custom_fields_manager?
    @custom_fields_manager = @options.custom_fields_manager

    first_comp = true
    Tracker.nonreactive =>
      # Isolated computation
      @custom_fields_changes_computation = Tracker.autorun =>
        @custom_fields_manager.getCustomFieldsSchema()

        if not first_comp
          @emit "custom_fields_changed"
        else
          first_comp = false

        return
    @setupGetSchemaExtendedWithCustomFieldsSameTickCacheClear()

  @on "custom_fields_changed", =>
    @_destroyColumnsManagerContextMenu()
    @_setupColumnsManagerContextMenu()

    # Refresh view (so removed custom fields that are currently in the view will be removed)
    @setView(@getView())

    return

  @removed_custom_fields_manager = null
  @removed_custom_fields_changes_computation = null
  if @options.removed_custom_fields_manager?
    @removed_custom_fields_manager = @options.removed_custom_fields_manager

    first_comp = true
    Tracker.nonreactive =>
      # Isolated computation
      @removed_custom_fields_changes_computation = Tracker.autorun =>
        @removed_custom_fields_manager.getCustomFieldsSchema()

        if not first_comp
          @emit "removed_custom_fields_changed"
        else
          first_comp = false

        return

  @schema = null
  @grid_control_field = null
  @fixed_fields = null # will contain an array of the fields that can't be hidden or moved - in their order
  
  @_load_formatters() # Need to be called before @_loadSchema()
                      # to know which formatters can serve as tree control
                      # formatters
  @_loadSchema() # loads @schema and @grid_control_field

  # _init_view is the view we use when building slick grid for the
  # first time.
  # Calling @setView before init complete will change @_init_view value
  @_init_view = @_getDefaultView() # set @_init_view to the default view

  if (extra_fields = @options.default_view_extra_fields)?
    extra_fields = _.filter extra_fields, (extra_field) => _.findIndex(@_init_view, (field_def) => field_def.field == extra_field) == -1
    
    @_init_view = @_init_view.concat _.map(extra_fields, (field_id) -> {field: field_id})

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

  @_view_changes_dependency = new Tracker.Dependency()
  @on "grid-view-change", => @_view_changes_dependency.changed()

  @_setupFrozenColumnsMaintainer()

  @_columns_data = {}

  if @options.forced_metadata_affecting_fields
    @forced_metadata_affecting_fields = @options.forced_metadata_affecting_fields
  else
    @forced_metadata_affecting_fields = {} # to avoid the need to check existence we don't set to null

  @_need_double_header_height_count = 0

  @_load_editors()

  @_initCollectionItemsDescendantsFilterAwareChangesTracker()

  @options.preInit.call(@)

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

    # Remove from the _init_view any unknown fields.
    _extended_schema = @getSchemaExtendedWithCustomFields()
    @_init_view = _.filter @_init_view, (column) -> column.field of _extended_schema

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
      grid_control: @

    @_grid_data = new GridData @collection, grid_data_options

    # proxy grid_data methods we want to be able to call from the
    # grid control level
    for method_name in PACK.grid_data_proxied_methods # defined in globals.js
      do (method_name) =>
        @[method_name] = (...args) -> @_grid_data[method_name].apply(@_grid_data, args)

    @container.addClass "grid-control"

    @_grid = new Slick.Grid @container, @_grid_data, columns, slick_options

    JustdoHelpers.setupHandlersRegistry(@)

    @_setupGridEventsSubscriptionsHooks()
    @_setupDefaultGridEvents()

    @_setColumnsStateMaintainersTrackerForView(@_init_view)
    @_initStatesClassesComputations()

    #@_grid.setSelectionModel(new Slick.RowSelectionModel())

    @_init_plugins()
    @_init_jquery_events()

    @_grid_data.on "pre_rebuild", =>
      @emit "pre_rebuild"

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

      @_grid_data.once "rebuild", (diff, items_ids_with_changed_children) =>
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
              smart_guess: true

        # tree_change, full_invalidation=true
        @logger.debug "Rebuild ready"
        @emit "rebuild_ready", {items_ids_with_changed_children}
        @emit "tree_change", true

        if not @_ready
          @_ready = true
          @ready.set true
          @logger.debug "Ready"
          @emit "ready"

        return

    @_grid_data.on "grid-item-changed", (row, fields) =>
      field_id_to_col_id = @getFieldIdToColumnIndexMap()

      extended_schema = @getSchemaExtendedWithCustomFields()

      for field in fields
        field_def = extended_schema[field]
        if field_def? and (field_def.grid_effects_metadata_rendering or field of @forced_metadata_affecting_fields)
          @_grid.invalidateRow(row)
          @_grid.render()

          # no need to continue updating the rest of the cells, as we redraw
          # the entire row
          break

        if field_id_to_col_id[field]?
          # Invalidate field column if in present grid
          @_grid.updateCell(row, field_id_to_col_id[field], true) # true is to allow the same cell to update twice on the same tick

        # When grid-data informs us that a field data updated in the db (the "grid-item-changed" event),
        # even if that field doesn't exist in the grid (hidden column) trigger invalidation to all its
        # dependent fields that are existing in the grid, and if they are of formatters that have the
        # 'invalidate_ancestors_on_change' option set to one of ["structure-and-content", "structure-content-and-filters"]
        # trigger ancestors invalidation as well.
        for dependent_field in @getAllDependentFields(field, extended_schema)
          if field_id_to_col_id[dependent_field]?
            @_grid.updateCell(row, field_id_to_col_id[dependent_field], true) # true is to allow two cells update on the same tick, an example for a case where it is necessary, set it to false, from the grid, play the time tracker play button, stop it, you'll see that it won't turn on (the private field for the running task collide with the update to the resources, resulting for a need to update twice on the same tick)

            if (dependent_field_formatter = extended_schema[dependent_field].grid_column_formatter)?
              # If we can determine the formatter
              if (formatter_definition = @getFormatterDefinition(dependent_field_formatter))?
                # If we can determine the formatter definition
                if formatter_definition.invalidate_ancestors_on_change in ["structure-and-content", "structure-content-and-filters"]
                  # If the formatter defines that ancestors should invalidate, invalidate ancestors as well
                  @_invalidateItemAncestorsFieldsOfFormatterType(@_grid_data.getItem(row)._id, dependent_field_formatter, {changed_fields_array: [dependent_field], update_self: false})

      # tree_change, full_invalidation=false
      @emit "tree_change", false

    @_grid_data.on "edit-failed", (err) =>
      console.error @_error "edit-failed", err

    @_grid_data.on "section-state-var-set", (section_id, var_name, new_val, regard_as_default_value) =>
      @emit "section-state-var-set", section_id, var_name, new_val, regard_as_default_value
      return

    @_grid.onCellChange.subscribe (e, edit_req) =>
      {new_value, row, cell} = edit_req

      field = @getCellField(cell)

      current_item = this._grid_data.getItem(row)
      path = this._grid_data.grid_tree[edit_req.row][2]

      friendly_args = @getFriendlyArgsForDocFieldAndPath(current_item, field, path)

      # Note this isn't the only place where we respect customStorageMechanism
      # search for grid_column_custom_storage_mechanism to find other places if
      # you change anything
      if (customStorageMechanism = friendly_args.schema.grid_column_custom_storage_mechanism)?
        if not customStorageMechanism(friendly_args, new_value)
          @_grid.updateCell(row, cell, true)
      else
        @_grid_data.edit(current_item._id, field, new_value)

      return

    @_grid.onEditCell.subscribe (e, details) =>
      # lock grid data while editing the cell
      @_grid_data._lock()

      @emit "edit-cell", {field: details.column.field, details, e}

      return true

    @_grid.onCellEditorDestroy.subscribe (e, details) =>
      @_grid_data?._release(true)

      @emit "cell-editor-destroyed", {e, details}

      return true

    @_grid.onValidationError.subscribe (e, validation_obj) =>
      JustdoSnackbar.show
        text: "#{validation_obj.validationResults.msg}"

      return

    @_grid.onScroll.subscribe (e, scrolls) =>
      @emit "viewport-scroll", {scrollLeft: scrolls.scrollLeft, scrollTop: scrolls.scrollTop}

      return

    @_grid.onViewUpdated.subscribe (e, performed_update) =>
      # Note, not all the view changes will trigger this, e.g change of field width from the header
      @once "grid-view-change", -> # grid-view-change will always be called following onViewUpdated
        Meteor.defer => # Defer to allow the filters to take effect, in case that filters changed
          # This one is mainly to bring back the row to the view following filters change
          performed_update.ensureActiveCellKeptInViewPort()
          return
        return

      return

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

  getAllDependentFields: (field_id, extended_schema=null) ->
    # Returns all the fields that are depending on field_id

    if not extended_schema?
      # Optimization, the user can provide his own extended_schema to avoid recalculating it
      extended_schema = @getSchemaExtendedWithCustomFields()

    if not (field_def = extended_schema[field_id])?
      # Some fields might not have field definition in the schema (example, custom private
      # fields used ad hoc to save state by plugins)

      return []

    extended_dependent_fields = []
    for extended_schema_field_id, extended_schema_field_def of extended_schema
      if extended_schema_field_def.custom_field == true
        # For the builtin fields we automatically build the grid_dependent_fields
        # based on grid_dependencies_fields in: @_loadSchema() so no need to redo
        # here.
        if not extended_schema_field_def.grid_dependencies_fields? or not _.isArray(extended_schema_field_def.grid_dependencies_fields)
          continue

        if field_id in extended_schema_field_def.grid_dependencies_fields
          extended_dependent_fields.push extended_schema_field_id

    return _.union(field_def.grid_dependent_fields or [], extended_dependent_fields)

  _error: JustdoHelpers.constructor_error

  getViewColumnsAffectedByFieldArrayChangesThatUseFormatterType: (fields_array, formatter_type) ->
    # fields_array is an array of fields_ids
    #
    # Returns columns ids (don't confuse with fields ids) of columns that either linked directly
    # to a field_id in fields_array, (i.e. their field_id is is in fields_array) or has in their
    # grid_dependencies_fields a field that is in fields_array.
    #
    # In addition, require the formatter_type to be the specified formatter_type.

    # First find all the visible columns, see whether any of them of formatter_type.

    grid_schema = @getSchemaExtendedWithCustomFields()

    all_columns_ids = _.map @getView(), (col) -> col.field # col.field as a term is wrong, it is actually the column_id and not the field_id

    columns_ids_of_formatter_type_affected_by_fields_array =
      _.filter all_columns_ids, (column_id) ->
        column_def = grid_schema[column_id]

        if column_def.grid_column_formatter == formatter_type
          if column_id in fields_array # XXX The mix between columns ids and columns fields ids is an historical mistake that we don't have the resources to fix at the moment.
            return true

          if (grid_dependencies_fields = column_def.grid_dependencies_fields)?
            for dependency_field in grid_dependencies_fields
              if dependency_field in fields_array
                return true

        return false

    return columns_ids_of_formatter_type_affected_by_fields_array

  _setupFrozenColumnsMaintainer: ->
    _frozen_columns_mode = false
    _frozen_columns_mode_rv = new ReactiveVar _frozen_columns_mode

    @isFrozenColumnsMode = -> _frozen_columns_mode_rv.get()

    @getColumnWidthHiddenByFrozenColumnsNonReactive = (column_field_id) ->
      # Returns 0 if:
      #
      #   We aren't in frozen mode, or
      #   If we are in frozen mode but no part of the column is hidden by the frozen columns, or
      #   Column_id is frozen itself, or
      #   column_field_id isn't in the current view
      #
      # Otherwise, returns the width in pxs hidden by the frozen columns.
      if not _frozen_columns_mode
        return 0

      current_scroll_left = @getViewportScrollLeft()

      width_occupied_by_frozen_columns = 0
      total_width_of_preceding_columns = 0
      target_column_width = 0
      for column in @getView()
        if column.frozen is true
          if column.field == column_field_id
            return 0 # Frozen column can't be hidden, just return 0

          width_occupied_by_frozen_columns += column.width

        if column.field == column_field_id
          target_column_width = column.width
          break

        total_width_of_preceding_columns += column.width

      hidden_px = -total_width_of_preceding_columns + current_scroll_left + width_occupied_by_frozen_columns

      if hidden_px <= 0
        return 0

      return Math.min(hidden_px, target_column_width)

    $current_css_block = null

    container_class_name = "frozen-columns-mode"

    getHeaderColumnSelector = (column_field_id) =>
      grid_uid = @getGridUid()

      return """##{grid_uid + column_field_id}.slick-header-column"""

    slickGridOnScrollFn = (e, scrolls) =>
      # e might be null, don't use it

      # At the moment we support only the first column freeze, hence "title"
      $(getHeaderColumnSelector("title")).css("left", "#{scrolls.scrollLeft}px")

      return

    slickGridOnEditCellFn = (e, details) =>
      column_field_id = details.column.field

      if (hidden_pixels = @getColumnWidthHiddenByFrozenColumnsNonReactive(column_field_id)) > 0
        total_width_of_preceding_columns = 0
        width_occupied_by_frozen_columns = 0

        for column in @getView()
          if column.frozen is true
            width_occupied_by_frozen_columns += column.width

          if column.field == column_field_id
            break

          total_width_of_preceding_columns += column.width

        @setViewportScrollLeft(total_width_of_preceding_columns - width_occupied_by_frozen_columns)

      return

    initSlickGridOnScrollFnEffect = =>
      return slickGridOnScrollFn(null, {
        scrollTop: @getViewportScrollTop()
        scrollLeft: @getViewportScrollLeft()
      })

    clearSlickGridOnScrollFnEffect = ->
      $(getHeaderColumnSelector("title")).css("left", "")

      return

    updateFrozenColumnsMode = (new_view) =>
      $current_css_block?.remove()

      frozen_columns_css = ""

      for column in new_view
        if column.frozen is true
          frozen_columns_css += """#{getHeaderColumnSelector(column.field)} {z-index: 2;} """ # 1 is the grid gantt's z-index, we want to be above it

      $current_css_block = JustdoHelpers.loadCssBlock frozen_columns_css

      @container.addClass container_class_name

      if not _frozen_columns_mode
        # If we are entering frozen columns mode, meaning, if before this call
        # to updateFrozenColumnsMode we were not in a frozen columns mode
        # setup the slick grid event
        initSlickGridOnScrollFnEffect()
        @_grid.onScroll.subscribe(slickGridOnScrollFn)
        @_grid.onEditCell.subscribe(slickGridOnEditCellFn)

      _frozen_columns_mode = true
      _frozen_columns_mode_rv.set _frozen_columns_mode

      return

    exitFrozenColumnsMode = =>
      if $current_css_block?
        $current_css_block.remove()
        $current_css_block = null

      @container.removeClass container_class_name

      @_grid?.onScroll.unsubscribe(slickGridOnScrollFn)
      @_grid?.onEditCell.unsubscribe(slickGridOnEditCellFn)
      clearSlickGridOnScrollFnEffect()

      _frozen_columns_mode = false
      _frozen_columns_mode_rv.set _frozen_columns_mode

      return

    viewChangeCb = (new_view) =>
      if not new_view? # @on "init" doesn't pass the new_view argument
        new_view = @getView()

      if new_view[0].frozen isnt true # the _validateView ensures that if there are frozen fields, they are all in the beginning.
        exitFrozenColumnsMode()

        return
      
      updateFrozenColumnsMode(new_view)

      return

    @on "init", viewChangeCb
    @on "grid-view-change", viewChangeCb

    @onDestroy ->
      exitFrozenColumnsMode()
      
      return

    return

  _invalidateItemAncestorsFieldsOfFormatterType: (items_ids, formatter_type, options) ->
    # This method looks for columns that uses formatter_type, it invalidates all the
    # ancestors of items_ids that appears in the grid.

    # items_ids can be either array of ids, or array of arrays of ids. We use the first item
    # type to determine the type.
    # (Done to save the computational waste of concatenating more than one array of items_ids
    # that need processing)

    # ## options
    #
    # ### changed_fields_array
    # 
    # default: undefined
    #
    # Specifies the fields that had been changed, pass this option to limit the
    # update only to columns that are affected by the fields that been change to optimize the run.
    # 
    # If not provided or (null/undefined) we'll assume all the fields of items_ids had been changed
    # and will invalidate all the ancestors' columns of type formatter_type .
    #
    # ### update_self
    #
    # default: false
    #
    # If set to false, we will update only the ancestors of items_ids.
    #
    # If set to true, we will also update items_ids itself - useful when we pass the
    # parents we want to update as items_ids and don't let _invalidateItemAncestorsFieldsOfFormatterType
    # to find them. In formatter_type, particular we use this feature on item remove and parents change.
    #
    # true value is useful in cases where the item or an item's parent removed
    # in such case you can pass the parent that had been removed 
    # Finds the calculated fields in the list of options.changed_fields_array
    # and then updates them in all the ancestors of items_ids in the grid
    # (to reflect the change upwards in the tree)

    if _.isString items_ids
      items_ids = [items_ids]

    if _.isArray items_ids[0]
      items_ids_arrays = items_ids
    else
      items_ids_arrays = [items_ids]

    if not options?
      options = {}

    {changed_fields_array, update_self} = options

    if not changed_fields_array?
      changed_fields_array = _.keys @getFieldIdToColumnIndexMap()

    if not update_self?
      update_self = false

    affected_view_columns_of_formatter_type =
      @getViewColumnsAffectedByFieldArrayChangesThatUseFormatterType(changed_fields_array, formatter_type)

    if affected_view_columns_of_formatter_type.length == 0
      # No calculated field changed
      return

    processed_items_ids = {}
    ancestor_paths = {}
    for items_ids_array in items_ids_arrays
      for item_id in items_ids_array
        if item_id == "0"
          continue

        if item_id of processed_items_ids
          continue

        processed_items_ids[item_id] = true

        item_paths = @_grid_data.getAllCollectionItemIdPaths(item_id)

        if not item_paths?
          # item_id no longer exists...

          continue

        for path in item_paths
          if not update_self
            path = GridData.helpers.getParentPath(path)

          parent_path_sub_paths = GridData.helpers.getAllSubPaths(path)

          for ancestor_path in parent_path_sub_paths
            if ancestor_path != "/" and ancestor_path not in ancestor_paths 
              ancestor_paths[ancestor_path] = true

    if _.isEmpty ancestor_paths
      return

    column_id_to_column_index_map = @getColumnsIdsToColumnIndexMap()
    columns_ids_to_update = _.values(_.pick(column_id_to_column_index_map, affected_view_columns_of_formatter_type))

    for ancestor_path of ancestor_paths
      # If row for the ancestor path exists in the visible grid
      if (row = @_grid_data.getPathGridTreeIndex(ancestor_path))?
        for col_id in columns_ids_to_update
          # For every ancestor updated with a *new* value, trigger invalidation to all dependent fields of its item
          pre_update_value = $(@_grid.getCellNode(row, col_id)).html()
          @_grid.updateCell(row, col_id)
          post_update_value = $(@_grid.getCellNode(row, col_id)).html()

          if pre_update_value != post_update_value
            # Presented value updated, update dependents fields
            field_updated = @getSlickGridColumns()[col_id].field

            if not _.isEmpty(dependent_fields = @getAllDependentFields(field_updated))
              field_id_to_col_id = @getFieldIdToColumnIndexMap()
              # Can be optimized by both providing extended_schema (see @getAllDependentFields definition),
              # and by caching dependencies cache

              for dependent_field_id in dependent_fields
                if field_id_to_col_id[dependent_field_id]?
                  # If present in the grid, update
                  @_grid.updateCell(row, field_id_to_col_id[dependent_field_id])

    return

  getColumnsIdsToColumnIndexMap: ->
    # Returns an object of the form presented in the following example:
    #
    # {
    #   "title": 0
    #   "subject": 1
    # }
    return _.object(_.map @getSlickGridColumns(), (cell, i) -> [cell.id, i])

  getFieldIdToColumnIndexMap: ->
    # Obsolete, due to wrong terminology used back then.
    return @getColumnsIdsToColumnIndexMap()

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
          # Defined in grid_control-static-methods.coffee
          default_non_tree_control_formatter_and_editor = 
            GridControl.getDefaultFormatterAndEditorForType(def.type)

          default_tree_control_formatter = "textWithTreeControls"
          default_tree_control_editor = "TextareaWithTreeControlsEditor"

          if def.type is String
            set_default_formatter(def, default_tree_control_formatter,
                                          default_non_tree_control_formatter_and_editor.formatter)

            set_default_editor(def, default_tree_control_editor,
                                      default_non_tree_control_formatter_and_editor.editor)

          if def.type is Date
            set_default_formatter(def, default_tree_control_formatter,
                                          default_non_tree_control_formatter_and_editor.formatter)

            set_default_editor(def, default_tree_control_editor,
                                      default_non_tree_control_formatter_and_editor.editor)

          if def.type is Boolean
            set_default_formatter(def, default_tree_control_formatter,
                                          default_non_tree_control_formatter_and_editor.formatter)

            set_default_editor(def, default_tree_control_editor,
                                      default_non_tree_control_formatter_and_editor.editor)

          else
            # For other types, same as String
            set_default_formatter(def, default_tree_control_formatter,
                                          default_non_tree_control_formatter_and_editor.formatter)

            set_default_editor(def, default_tree_control_editor,
                                      default_non_tree_control_formatter_and_editor.editor)


          # Validate formatter/editor and build fixed_fields
          if not grid_control_field_found and not def.grid_pre_grid_control_column
            grid_control_field_found = true
            fixed_fields.push field_name

            @grid_control_field = field_name

            # grid control field must be a default field
            if not def.grid_default_grid_view
              err "As the grid control field, `#{field_name}` must have grid_default_grid_view option set to true"
            
            if not(def.grid_column_formatter in @_tree_control_fomatters)
              err "As the grid control field, `#{field_name}` must have grid_column_formatter option set to one of the grid-control formatter as set in @_tree_control_fomatters"
          else
            if def.grid_column_formatter in @_tree_control_fomatters
              err "`#{field_name}` is not the grid control field, it can't use `#{def.grid_column_formatter}` as its formatter as it's a grid-control formatter, as defined in @_tree_control_fomatters"

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

      for prop_name in ["grid_values", "grid_removed_values"]
        # Init grid_values
        if def[prop_name]?
          if _.isFunction(def[prop_name])
            def[prop_name] = def[prop_name](@)
          else
            def[prop_name] = _.extend({}, def[prop_name])

          for option_id, option of def[prop_name]
            if not option.txt?
              err "Each value of #{prop_name} must have a txt property"

      for prop_name in ["grid_ranges"]
        # Init grid_ranges
        if def[prop_name]?
          if _.isFunction(def[prop_name])
            def[prop_name] = def[prop_name](@)

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

            if dependency_def.grid_dependent_fields.indexOf(dependent_field_name) == -1
              dependency_def.grid_dependent_fields.push(dependent_field_name)

    @fixed_fields = fixed_fields
    @schema = schema

    return schema

  getSchemaExtendedWithCustomFieldsSameTickCacheId: (include_removed_fields = false) ->
    return "getSchemaExtendedWithCustomFields-#{include_removed_fields}-#{@grid_control_uid}"

    return 

  setupGetSchemaExtendedWithCustomFieldsSameTickCacheClear: ->
    @custom_fields_manager.on "custom-fields-updated", =>
      for include_removed_fields in [true, false]
        same_tick_cache_id = @getSchemaExtendedWithCustomFieldsSameTickCacheId(include_removed_fields)

        JustdoCoreHelpers.sameTickCacheUnset(same_tick_cache_id)

      return

    return

  getSchemaExtendedWithCustomFields: (include_removed_fields = false) ->
    same_tick_cache_id = @getSchemaExtendedWithCustomFieldsSameTickCacheId(include_removed_fields)

    if (sametick_cached_schema = JustdoHelpers.sameTickCacheGet(same_tick_cache_id))?
      return sametick_cached_schema

    schema = _.extend {}, @schema # shallow copy schema

    if not @custom_fields_manager?
      return schema

    custom_fields_schema =
      @custom_fields_manager.getCustomFieldsSchema()

    _.extend schema, custom_fields_schema

    # Remove disabled fields from schema, we regard disabled fields the
    # same way as removed fields for the matter of the include_removed_fields
    # argument
    if not include_removed_fields
      for field_id, field_def of schema
        if field_def.disabled? and field_def.disabled is true
          delete schema[field_id]

    if include_removed_fields
      if not @removed_custom_fields_manager?
        return schema

      # Make a shallow copy of the returned schema, as we are going to replace the objects
      # provided with new object prototypically inherit from the origin ones that adds the
      # 'obsolete' property set to true - to allow distinguishing between removed and current
      # custom fields.
      removed_custom_fields_schema =
        _.extend {}, @removed_custom_fields_manager.getCustomFieldsSchema()

      # Add the obsolete property to all the removed custom fields.
      for custom_field_id, field_schema of removed_custom_fields_schema
        removed_custom_fields_schema[custom_field_id] = Object.create(field_schema)
        removed_custom_fields_schema[custom_field_id].obsolete = true

      _.extend schema, removed_custom_fields_schema

    JustdoHelpers.sameTickCacheSet(same_tick_cache_id, schema)

    return schema

  _validateView: (view) ->
    # Returns true if valid view, throws a "grid-control-invalid-view" error otherwise
    err = (message) =>
      throw @_error "grid-control-invalid-view", message

    if view.length < @fixed_fields.length
      err "View must include all fixed fields #{JSON.stringify(@fixed_fields)}"

    found_fields = {}

    fixed_fields = @fixed_fields.slice() # copy

    frozen_column_allowed = true
    for column in view
      field_name = column.field

      if (current_fixed_field = fixed_fields.shift())? and current_fixed_field != field_name
        err "View must include all the fixed fields in their order - couldn't find #{current_fixed_field}"

      if field_name of found_fields
        err "Provided view specified more than one column for the same field `#{field_name}`"
      found_fields[field_name] = true

      extended_schema = @getSchemaExtendedWithCustomFields()
      if not(field_name of extended_schema)
        err "Provided view has a column for an unknown field `#{field_name}`"

      field_def = extended_schema[field_name]
      if not field_def.grid_visible_column
        err "Provided view has a column for non-visible field `#{field_name}`"        

      if column.frozen? and not _.isBoolean column.frozen
        err "Provided view has a column with invalid 'frozen' property value, must be a Boolean"

      if frozen_column_allowed
        if not column.frozen? or not column.frozen
          # Once the first non-frozen column found, all the rest can't be frozen
          frozen_column_allowed = false
        else
          # This else blocks, for now, the ability to have more than one frozen field.
          #
          # The reason for this limit is the current {position: sticky} based implementation
          # of the frozen column that doesn't work well when there's more than one frozen column.
          #
          # In the future, when frozen columns are implemented differently, just remove this else
          # to allow more frozen columns.
          #
          # More issues to handle with more than one frozen columns:
          #
          # (0. The above mentioned issue with sticky position).
          # 1. The drag and drop of header columns should be limited for the second column on (for
          # the first column we get that for free).
          # 2. The frozen columns headers position calculation when scrolling left right should be
          # calculated beyond the first column that is the only one calculated today. 
          frozen_column_allowed = false
      else
        if column.frozen is true
          err "Provided view has a frozen column in a place where frozen columns aren't allowed `#{field_name}`"

    return true

  _getColumnsStateMaintainersFromView: (view) ->
    # This method assumes that the view passed to it passed @_validateView

    # Returns object of the form:
    #
    # { column_id: columnStateMaintainer }
    #
    # For all the columns present in the grid that we have column state maintainer
    # for their formatters.

    state_maintainers = {}

    extended_schema = @getSchemaExtendedWithCustomFields()

    for column_def in view
      field = column_def.field
      field_def = extended_schema[field]

      if (column_state_maintainer = @_columns_state_maintainers[field_def.grid_column_formatter])?
        state_maintainers[field] = column_state_maintainer

    return state_maintainers

  _state_maintainers_trackers = null
  _resetColumnsStateMaintainersTrackers: ->
    if @_state_maintainers_trackers?
      for tracker in @_state_maintainers_trackers
        tracker.stop()

    @_state_maintainers_trackers = []

    @logger.debug "Columns state maintainers initialized"

    return

  _setColumnsStateMaintainersTrackerForView: (view) ->
    @_resetColumnsStateMaintainersTrackers()

    columns_state_maintainers = @_getColumnsStateMaintainersFromView(view)

    init_phase = true
    for column_id, columnStateMaintainer of columns_state_maintainers
      do (column_id, columnStateMaintainer) =>
        computation = new Tracker.autorun =>
          if not init_phase
            # If recalculated after init phase, means we need to invalidate
            # the column

            @logger.debug "Column #{column_id} state maintainer trigger column recalculation"

            Tracker.nonreactive =>
              @invalidateColumns([column_id])

              return

          columnStateMaintainer({column_id: column_id})

          return

        @_state_maintainers_trackers.push computation

    init_phase = false

    @logger.debug "State maintainers trackers updated"

    return

  _getColumnsStructureFromView: (view) ->
    # This method assumes that the view passed to it passed @_validateView
    columns = []

    extended_schema = @getSchemaExtendedWithCustomFields()

    first = true
    for column_def in view
      field = column_def.field
      field_def = extended_schema[field]

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

      if column_def.frozen?
        column.frozen = column_def.frozen
      else if field_def.grid_default_frozen_column?
        column.frozen = field_def.grid_default_frozen_column

      if field_def.grid_fixed_size_column? and field_def.grid_fixed_size_column
        column.resizable = false
        column.minWidth = 0

      if field_def.grid_values?
        column.values = field_def.grid_values
      else
        column.values = null

      if field_def.grid_removed_values?
        column.removed_values = field_def.grid_removed_values
      else
        column.removed_values = null

      if column_def.grid_effects_metadata_rendering
        column.grid_effects_metadata_rendering = true

      if field_def.grid_column_filter_settings?
        column.filter_settings = field_def.grid_column_filter_settings

        if column_def.filter?
          column.filter_state = column_def.filter
        else
          column.filter_state = null

      if field_def.grid_ranges?
        column.grid_ranges = field_def.grid_ranges
      else
        column.grid_ranges = null

      columns.push column

    columns

  _getDefaultView: ->
    if GridControl.forced_base_default_view?
      return GridControl.forced_base_default_view
    
    view = []

    extended_schema = @getSchemaExtendedWithCustomFields()

    for field_name, field_def of extended_schema # We assume extended_schema passed validation
      if field_def.grid_default_grid_view
        field_view =
          field: field_name,

        if field_def.grid_default_width?
          field_view.width = field_def.grid_default_width

        if field_def.grid_default_frozen_column is true
          field_view.frozen = field_def.grid_default_frozen_column

        if (grid_default_grid_view_position = field_def.grid_default_grid_view_position)?
          field_view.position = field_def.grid_default_grid_view_position
        else
          field_view.position = 100

        # Uncomment for testing purpose to have filters active on load
        # if field_def.grid_column_filter_settings?
        #   field_view.filter = ["done"]

        view.push field_view

    ordered_view = []
    first_item = view.shift()

    ordered_view = _.sortBy view, "position"
    ordered_view.unshift(first_item)

    _.map ordered_view, (field_view) -> delete field_view.position

    # Example of adding fields to the default view conditionally
    #
    # if APP?.modules?.project_page?.curProj()?.isCustomFeatureEnabled("justdo_private_follow_up")
    #   # Starting from late March 2019 we move towards replacing the follow up field that is shared with
    #   # all the members to the private follow up field, realising that follow ups are private and different
    #   # task stake holders might want to set different follow ups to the same task.
    #   #  * We enabled the Private follow up plugin by default.
    #   #  * Here, we make the private follow up field part of the default grid view.
    #   #    we show it after the due date field, if exists, or else in the end of the view.

    #   private_field_position = view.length
    #   if (due_date_field_pos = _.findIndex(view, (field_def) -> field_def.field == "due_date")) > -1
    #     private_field_position = due_date_field_pos

    #   view.splice(private_field_position, 0, {field: "priv:follow_up", width: 142})

    return ordered_view

  getViewFieldsSubstitutionMap: ->
    allowed_fields = @getSchemaExtendedWithCustomFields()

    substituting_fields = {}

    _.each allowed_fields, (allowed_field, field_id) ->
      if allowed_field.grid_column_substitue_field?
        substituting_fields[allowed_field.grid_column_substitue_field] = field_id

      return


    return substituting_fields

  setView: (view) ->
    view = view.slice() # shallow copy

    # Ignore columns that aren't part of the schema or the custom fields definition
    allowed_fields = @getSchemaExtendedWithCustomFields()

    # Perform translation to substitute fields
    substituting_fields = @getViewFieldsSubstitutionMap()

    _.each view, (field_def) ->
      if field_def.field of substituting_fields
        field_def.field = substituting_fields[field_def.field]

      return

    view = _.filter view, (column) ->
      if column.field not of allowed_fields
        return false

      return true

    view = lodash.uniqBy(view, "field") # Since we introduced the concept of substituting_fields, we might have duplicate for the same field

    @_validateView(view)

    columns = @_getColumnsStructureFromView view
    if not @_initialized
      @_init_view = columns
    else
      active_row = @getCurrentRowNonReactive()

      update_type = @_grid.setColumns columns

      # If the last selected cell will be removed as a result of updating the view,
      # this.getCurrentRowNonReactive() that rely on the underlying selected cell
      # will start return undefined, we need to re-activate the row.
      if active_row? and not @getCurrentRowNonReactive()?
        @activateRow(active_row)

      if not update_type? # null means nothing changed
        return

      new_view = @getView()

      @_setColumnsStateMaintainersTrackerForView view

      if update_type # true means dom rebuilt
        @emit "columns-headers-dom-rebuilt", new_view

      @emit "grid-view-change", new_view

  getView: ->
    columns = @_grid.getColumns()

    view = _.map columns, (column) ->
      # If a column has no field we regard it as a misc column like the row handler
      if column.field?
        ret =
          field: column.field
          width: column.width
          filter: column.filter_state

        if column.frozen is true
          ret.frozen = column.frozen
        
        return ret

      return false

    view = _.filter view, (column) -> not(column is false)

    return view

  getViewReactive: ->
    # Originally, @getView() wasn't reactive, to avoid unexpected bug, we introduce another
    # method to handle reactivity.
    @_view_changes_dependency.depend()

    return @getView()

  invalidateOnViewChange: ->
    view = @getView()

    return view

  addFieldToView: (field_id, position) ->
    view = @getView()

    if position?
      # add field after clicked item
      view.splice(position, 0, {field: field_id})
    else
      view.push({field: field_id})

    @setView(view)

    return

  fieldsMissingFromView: ->
    current_view_fields = _.map @getView(), (col) -> col.field
    visible_fields = []
    extended_schema = @getSchemaExtendedWithCustomFields()
    for field, field_def of extended_schema
      if field_def.grid_visible_column
        visible_fields.push field
    missing_fields = _.filter visible_fields, (field) -> not(field in current_view_fields)

    return missing_fields

  getCellField: (cell_id) -> @getSlickGridColumns()[cell_id].field

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

  getEventRow: (e) ->
    if not (cell = @_grid.getCellFromEvent(e))?
      return null

    return cell.row

  getEventItem: (e) ->
    if not (row = @getEventRow(e))?
      return null

    return @_grid_data.getItem(row)

  getEventPath: (e) ->
    if not (cell = @_grid.getCellFromEvent(e))?
      return null

    return @_grid_data.getItemPath(cell.row)

  editEventCell: (e, cb) ->
    # Enters edit mode in the event's cell
    #
    # cb will be called if cell edit mode entered successfully
    {row, cell} = @_grid.getCellFromEvent(e)

    @_grid.setActiveCell(row, cell, false)

    if @eventCellIsActiveCell(e)
      @editActiveCell()
      
      if (cell_editor = @_grid.getCellEditor())?
        cb(cell_editor)
    
    return

  getEventFormatterDetails: (e) ->
    {row, cell} = @_grid.getCellFromEvent(e)
    
    column_view_state = @getView()[cell]
    field_name = column_view_state.field
    extended_schema = @getSchemaExtendedWithCustomFields()
    column_field_schema = extended_schema[field_name]

    if column_field_schema?
      formatter_name = column_field_schema.grid_column_formatter
      formatter_obj = GridControl.getFormatters()[formatter_name]

    return {
      field_name
      column_view_state
      column_field_schema
      formatter_obj
      formatter_name
    }

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
  activateRow: (row, cell = 0, scroll_into_view = true, resulted_from_smart_guess=false) ->
    @_grid.setActiveCell(row, cell, scroll_into_view)

    @emit "row-activated", row, cell, scroll_into_view, resulted_from_smart_guess

    return

  activatePath: (path, cell=0, options) ->
    if not path?
      @logger.debug "activatePath: no path provided"
      
      return
    
    if not options?
      options = {}

    options = _.extend {expand: true, scroll_into_view: true, smart_guess: false}, options

    # If options.expand is set to false, don't expand path ancestors
    # in case path isn't visible due to collapsed ancestor/s,
    # in which case we'll avoid activation.

    # If options.smart_guess is on, if we fail to find the requested path,
    # we will attempt to look for whether there's a path with
    # for an item_id equal to /the/last/*part* of the requested path.
    # If there's more than one path for this path, we will activate
    # one of them arbitrarily.

    # Return true if path activated successfuly, false otherwise
    path = GridData.helpers.normalizePath path

    resulted_from_smart_guess = false

    if options.smart_guess and not @_grid_data.pathExist path
      @logger.debug "activatePath: path `#{path}` doesn't exist, attempting smart-guess"

      potential_item_id = GridData.helpers.getPathItemId(path)

      if (alt_path = @_grid_data.getCollectionItemIdPath(potential_item_id))?
        @logger.debug "activatePath: smart-guess: alternative path found #{alt_path}"

        resulted_from_smart_guess = true

        path = alt_path
      else
        @logger.debug "activatePath: smart-guess: failed to find alternative"

        return false

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

          # We wait for the next pre_rebuild, since we might
          # be in an active rebuild process, in which case
          # rebuild_ready will call immediately.
          # (Remember events are sync and not next-tick)
          @once "pre_rebuild", =>
            @once "rebuild_ready", =>
              # post slick grid rebuild
              row = @_grid_data.getPathGridTreeIndex(path)

              if row?
                @activateRow(row, cell, options.scroll_into_view)
      else
        row = @_grid_data.getPathGridTreeIndex(path)

        @activateRow(row, cell, options.scroll_into_view, resulted_from_smart_guess)
    else
      @logger.debug "activatePath: path `#{path}` doesn't exist"

      return false

    return true

  activateCollectionItemId: (item_id, cell = 0, options) ->
    options = _.extend {force_pass_filter: false, readyCb: null}, options

    activate = =>
      result = @activatePath(@_grid_data.getCollectionItemIdPath(item_id), cell, options)

      JustdoHelpers.callCb options.readyCb, result

      return

    if options.force_pass_filter and
        (filter_items_ids = @_grid_data._filter_collection_items_ids)? and
        item_id not of filter_items_ids
          @forceItemsPassCurrentFilter item_id, activate
    else
      activate()

    return

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

          usersDiffConfirmationCb item_id, target_id, diff, wrappedConfirm, wrappedCancel, {action_name: "move"}

    return @_grid_data.movePath(path, new_location, cb, wrappedUsersDiffConfirmationCb)

  addParent: (item_id, new_parent, cb, usersDiffConfirmationCb) ->
    # A proxy to grid-data's addParent that takes care of using
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

          usersDiffConfirmationCb item_id, target_id, diff, wrappedConfirm, wrappedCancel, {action_name: "add"}

    return @_grid_data.addParent(item_id, new_parent, cb, wrappedUsersDiffConfirmationCb)

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
      @_grid_data?.unregisterMetadataGenerator(cb)
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

  getGridUid: -> @_grid.uid

  #
  # Columns Key Val DB
  #
  # All the involved methods aren't reactive, reactiveness on the column
  # level can be achived by the formatters's slickGridColumnStateMaintainer
  # option
  #
  _columns_data: null # initiated to object by the contructor
  setColumnData: (column_id, key, value) ->
    Meteor._ensure(@_columns_data, column_id)

    @_columns_data[column_id][key] = value

    return

  clearColumnData: (column_id, key) ->
    if @_columns_data[column_id]?
      # Note, if @_columns_data[column_id] doesn't exist, nothing to remove...
      delete @_columns_data[column_id][key]

    return

  getColumnData: (column_id, key) ->
    return @_columns_data[column_id]?[key]

  #
  # Grid editing lock
  #
  editing_locked: false
  _gridEditLockFn: (e) ->
    console.log "[grid-control] Editing locked"

    e.stopImmediatePropagation()

    return

  lockEditing: ->
    if @editing_locked
      return

    @editing_locked = true

    @_grid.onClick.subscribe(@_gridEditLockFn)

    return

  unlockEditing: ->
    if not @editing_locked
      return

    @editing_locked = false

    @_grid?.onClick.unsubscribe(@_gridEditLockFn)

    return

  getFieldDef: (field_id, throw_if_not_exists=true) ->
    extended_schema = @getSchemaExtendedWithCustomFields()

    if field_id not of extended_schema
      if throw_if_not_exists
        throw @_error "unknown-field-id", "Unknown field #{field_id}"
      else
        return undefined

    return extended_schema[field_id]

  isEditableField: (field_id) ->
    return @getFieldDef(field_id, false)?.grid_editable_column

  generateFieldEditor: (field_id, item_id) ->
    # We allow fields editor to be generated without item_id
    #
    # The usecase for that is to allow cases where the editor might be useful
    # to present without specific value, for example select editor, for the
    # purpose of presenting available options when editing the field options.

    if item_id?
      item = @collection.findOne(item_id)

      if not item?
        throw @_error "unknown-item-id", "Unknown item id: #{item_id}"

    extended_schema = @getSchemaExtendedWithCustomFields()

    field_def = @getFieldDef(field_id)

    if not @isEditableField(field_id)
      throw @_error "field-not-editable", "Field: #{field_id} is not editable"

    field_editor_id = field_def.grid_column_editor

    $container = $("<div>")
    editor_context = {
        grid: @_grid
        gridPosition: @_grid.absBox(@container.get(0), true) # true, will use the light-weight version of absBox
        position: {top: 0, left: 0, right: 0, bottom: 0}
        container: $container
        column: {id: field_id, field: field_id, values: field_def.grid_values}
        commitChanges: -> return
        cancelChanges: -> return
    }

    if item?
      editor_context.item = item

    editor = new @_editors[field_editor_id](editor_context)

    if item?
      editor.loadValue(item)

    destroyed = false
    destory = ->
      if destroyed
        return
      
      editor.destroy()

      destroyed = true

      return

    reloadEditorValueFromMinimongo = =>
      editor.loadValue(@collection.findOne(item_id, {fields: {"#{field_id}": 1}})) # don't use item, for case the item changed by someone else, while we were editing it.

      return

    cancel = =>
      # We don't deal here with a case where the editor was generated without item_id
      # we assume this method won't be called in such case.

      # Load original value
      if destroyed
        return

      reloadEditorValueFromMinimongo()

      return

    save = =>
      # We don't deal here with a case where the editor was generated without item_id
      # we assume this method won't be called in such case.

      if destroyed
        return

      if not editor.isValueChanged()
        return

      serialize_value = editor.serializeValue()

      if (customStorageMechanism = editor.context.schema.grid_column_custom_storage_mechanism)?
        friendly_args = @getFriendlyArgsForDocFieldAndPath(editor.context.item, editor.context.field_name, Tracker.nonreactive => editor.context.grid_control.getCurrentPath())
        if not customStorageMechanism(friendly_args, serialize_value)
          reloadEditorValueFromMinimongo()
      else
        update = {$set: {}}

        update.$set[field_id] = serialize_value

        if (items_updated_count = @collection.update(item_id, update)) == 0
          reloadEditorValueFromMinimongo()

      return

    saveAndExit = =>
      if destroyed
        return

      save()

      destory()

      return

    return {
      "$dom_node": $container
      editor: editor

      saveAndExit: saveAndExit
      cancel: cancel
      save: save
      destory: destory
    }

  onDestroy: (proc) ->
    # not to be confused with @destroy, onDestroy registers procedures to be called by @destroy()
    @_on_destroy_procedures.push proc

    return

  destroy: ->
    if @_destroyed
      return
    @_destroyed = true

    _.each @_on_destroy_procedures, (proc) -> proc()

    # In case init_dfd isn't resolved already, reject it
    @_init_dfd.reject()
    @initialized.set false
    @ready.set false

    if @_current_state_invalidation_protection_computation?
      @_current_state_invalidation_protection_computation.stop()

    @_destroyStatesClassesComputations()
    @_destroy_plugins()
    @_destroy_jquery_events()

    if @custom_fields_changes_computation?
      @custom_fields_changes_computation.stop()

    if @removed_custom_fields_changes_computation?
      @removed_custom_fields_changes_computation.stop()

    if @_grid_data?
      @_grid_data.destroy()
      @_grid_data = null

    if @_grid?
      @_grid.destroy()
      @_grid = null

    if @_operation_controllers?
      for op_controller_name, op_controller of @_operation_controllers
        op_controller.destroy()

    @_columns_data = null

    @_resetColumnsStateMaintainersTrackers()

    @emit "destroyed"

    @logger.debug "Destroyed"

  #
  # Grid querying / maintanace
  #
  getSlickGridColumns: ->
    return @_grid.getColumns()

  getSlickGridLength: ->
    return @_grid.getDataLength()

  invalidateColumns: (columns) ->
    # Gets a column id or array of columns ids look for them
    # if columns with corresponding names exists in slick grid
    # invalidate the cells in all of them.

    if not columns?
      return

    if _.isString columns
      columns = [columns]

    current_slick_grid_columns = @getSlickGridColumns()

    columns_nth_position = []
    # Find requested columns ids order
    for column_obj, nth_position in current_slick_grid_columns
      if column_obj.id in columns
        columns_nth_position.push(nth_position)

    if _.isEmpty columns_nth_position
      @logger.warn "invalidateColumns: couldn't find any of the requested columns #{columns.join()}"
      return

    if _.size(columns_nth_position) != columns.length
      @logger.warn "invalidateColumns: some requested columns aren't present in the tree, skipping them"

    for i in [0...@getSlickGridLength()]
      for j in columns_nth_position
        @_grid.updateCell(i, j, true) # true is to let more than one update on the same tick (to see a case where we must have it set to true: set it to false, enable the time tracker plugin and then enable/disable the resource planner - the on-grid indication for resources on task will be in-correct, the opposite to the resource planner installed state)

    return

  _setupGridEventsSubscriptionsHooks: ->
    @_grid.onClick.subscribe (e, cell) =>
      # Both false and e.stopImmediatePropagation() can be used to prevent entering edit mode.
      #
      # e.stopImmediatePropagation() will, in addition, stop processing other pending
      # handler, and propogate the event up the DOM tree (might be too strong, use with care)

      return @processHandlersWithBreakCondition("NormalModeOnClick", -> # breaking condition
        return e.isImmediatePropagationStopped()
      , e, @getFriendlyCellArgs(cell.row, cell.cell))

    @_grid.onBeforeEditCell.subscribe (e, cell) =>
      # Return false to avoid other handlers execution + avoid entering edit mode
      return @processHandlers("BeforeEditCell", e, @getFriendlyCellArgs(cell.row, cell.cell))

  _setupDefaultGridEvents: ->
    #
    # Disable edits if target element has the .slick-prevent-edit class
    #
    @register "NormalModeOnClick", (e, args) ->
      if $(e.target).hasClass("slick-prevent-edit")
        return false

      return true

    return

  #
  # getFriendlyCellArgs
  #
  getFriendlyCellArgs: (row, cell) ->
    field = @getCellField(cell)
    doc = @_grid_data?.getItem(row)
    grid_column_info = @_grid.getColumns()[cell]

    extended_schema = @getSchemaExtendedWithCustomFields()
    schema = extended_schema[field]

    friendly_args =
      self: @
      # We added self, in additional to the slick_grid reference below
      # as it might be easier to explain formatters developers that
      # the special formatters helpers assigned during formatters init process
      # are accessible through self instead of explaining the real
      # inheritance nature of formatters objects
      #
      # See how formatters are initiated to learn more

      row: row
      cell: cell
      path: @_grid_data?.getItemPath row

      value: doc?[field]
      field: field

      grid_control: @
      grid_data: @_grid_data
      slick_grid: @_grid

      grid_column_info: grid_column_info
      schema: schema
      doc: doc
      formatter_options: schema?.grid_column_formatter_options or {}

      formatter_name: schema.grid_column_formatter
      # With formatter_obj referencing to the original formatter object we
      # can access helper methods attached to that object. It is useful not
      # only to keep orginzation but to allow formatters
      # inheritence (see unicode_date as a usage example)
      formatter_obj: PACK.Formatters[@formatter_name]

    if (valueGenerator = schema?.grid_column_custom_value_generator)?
      friendly_args.value = valueGenerator(friendly_args)

    return friendly_args

  getFriendlyArgsForDocFieldAndPath: (doc, field, path) ->
    # * The assumption is that if @getFriendlyCellArgs weren't called, the field isn't in the grid
    # * We ask both path and doc: for cases the doc isn't in the grid at all, and for performance (of retrieving one from the other).
    # * Path is *kind of* optional
    row = cell = grid_column_info = null 

    extended_schema = @getSchemaExtendedWithCustomFields()
    schema = extended_schema[field]

    friendly_args =
      self: @
      # We added self, in additional to the slick_grid reference below
      # as it might be easier to explain formatters developers that
      # the special formatters helpers assigned during formatters init process
      # are accessible through self instead of explaining the real
      # inheritance nature of formatters objects
      #
      # See how formatters are initiated to learn more

      row: row
      cell: cell
      path: path

      value: doc[field]
      field: field

      grid_control: @
      grid_data: @_grid_data
      slick_grid: @_grid

      grid_column_info: grid_column_info
      schema: schema
      doc: doc
      formatter_options: schema?.grid_column_formatter_options or {}

      formatter_name: schema.grid_column_formatter
      # With formatter_obj referencing to the original formatter object we
      # can access helper methods attached to that object. It is useful not
      # only to keep orginzation but to allow formatters
      # inheritence (see unicode_date as a usage example)
      formatter_obj: PACK.Formatters[@formatter_name]

    if (valueGenerator = schema?.grid_column_custom_value_generator)?
      friendly_args.value = valueGenerator(friendly_args)

    return friendly_args

  isDocFieldAndPathEditable: (doc, field, path) ->
    friendly_args = @getFriendlyArgsForDocFieldAndPath(doc, field, path)

    before_edit_cell_events_handlers = @getHandlers("BeforeEditCell")

    for handler in before_edit_cell_events_handlers
      e = new Slick.EventData()
      res = handler(e, friendly_args) # Return false to avoid other handlers execution + avoid entering edit mode

      if res == false
        # False returned, stop execution (slick grid will notice it as well and won't take other handlers nor transition to edit mode)
        return false

    return true

  getFormatterDefinition: (formatter_id) -> GridControl.Formatters[formatter_id]

  getGridControlMux: -> @grid_control_mux # If this grid control initiated by a grid control multiplexer @grid_control will be assigned by the multiplexer.

  getMainGridControlOrSelf: ->
    # For grid controls that been initiated by a grid control multiplexer, it is
    # likely that non-main tabs will have only partial data of the main tab which 
    # will usually will have the data's natural tree representation, and hence
    # the most complete tree view (and the one in which the paths are most intuitive
    # to users/developers).
    #
    # If we aren't running under a grid control multiplexer, this will simply return
    # @

    if (main_tab = @grid_control_mux?._grid_controls_tabs?.main)?
      # If we are running under a grid control multiplexer, always use the main tab
      # (That should have the most complete data, which is needed for finding a
      # path for field_id)

      # Reminder, the main grid is always loaded by the multiplexer (for the rest of
      # the tab, we can't assume the grid_control is initiated).
      return main_tab.grid_control
    
    return @

  _setGridHeaderHeight: (height_px) ->
    # If height_px is undefined, resume to default

    grid_uid = @getGridUid()

    style_tag_class = "#{grid_uid}-cutom-grid-header-height"

    default_vertical_paddings = 4
    vertical_paddings = (height_px - 16) / 2 + default_vertical_paddings

    $(".#{style_tag_class}").remove()
    if height_px? # if not, we just remove, i.e. resuming to default
      $("html > head").append($("""<style class="#{style_tag_class}">.#{grid_uid} .slick-header-column { padding-top: #{vertical_paddings}px; padding-bottom: #{vertical_paddings}px; } .#{grid_uid}</style>"""));

    @_grid.resizeCanvas()

    return

  requireDoubleHeader: ->
    if @_need_double_header_height_count is 0
      @_setGridHeaderHeight(32)

    @_need_double_header_height_count += 1

    return

  releaseDoubleHeader: ->
    @_need_double_header_height_count -= 1

    if @_need_double_header_height_count is 0
      @_setGridHeaderHeight() # Resume to default

    return


  _initCollectionItemsDescendantsFilterAwareChangesTracker: ->
    self = @

    @_collection_items_tracked_for_filter_aware_descendants_changes = {}
    # _collection_items_tracked_for_filter_aware_descendants_changes Structure:
    # {
    #   "item_id": [ # An array because there can be more than one tracker for the same item_id
    #     {
    #       tracker_id: A random id for this tracker, so we can remove it when it isn't needed anymore
    #       direct_children_only: false # true / false
    #       descendants_changed_dep: new Tracker.Dependency() # The Dependency that we'll call the .changed()
    #                                                         # when descendants changed according to the
    #                                                         # tracker options.
    #       tracked_fields: [] # Either undefined, or an array of fields, if undefined, all fields are
    #                          # tracked
    #     }
    #   ]
    # }
    #
    # IMPORTANT-COMMENT-REGARDING-FILTERS-AND-DIRECT-CHILDREN-BEHAVIOUR, for direct_children_only,
    # for filter related changes, we don't have a reliable way to determine from which descendant
    # a change event received for a certain grid visible item.
    #
    # We don't know whether the change came from the item itself, from a direct child, or a deeper
    # descendant. All we can do is to avoid propagating higher than one level than the item from
    # which it received.
    #
    # Bottom line: don't rely on the correctness of filter-aware direct_children_only trackers. Build
    # your code in a way that redundant calls won't produce a bug.
    #
    # To learn more, see how the visible_tree_leaves_changes object returned by the grid-tree-filter-updated
    # event is constructed. Check the file: grid-control/lib/client/plugins/grid_views/filters/filters.coffee
    # look there for: VISIBLE_TREE_LEAVES_CHANGES_COMMENT

    announceTrackedItemChanged = (tracked_item_id, is_direct_children_changed, fields_affected) =>
      # fields_affected might be undefined, in which case we assume all the fields
      # are affected

      for tracker in @_collection_items_tracked_for_filter_aware_descendants_changes[tracked_item_id]
        if tracker.direct_children_only and not is_direct_children_changed
          continue

        if fields_affected?
          # When fields_affected is undefined - we assume all the fields are affected by this change,
          # hence no need to check intersection with the tracker tracked fields.
          if tracker.tracked_fields? and _.isEmpty(_.intersection(tracker.tracked_fields, fields_affected))
            continue

        tracker.descendants_changed_dep.changed()

      return

    @on "grid-tree-filter-updated", (data) =>
      {visible_tree_leaves_changes} = data

      if _.isEmpty(@_collection_items_tracked_for_filter_aware_descendants_changes)
        # Nothing to do...
        return

      if not (visible_tree_leaves_changes = data.visible_tree_leaves_changes)?
        # Nothing to do...
        return

      # Read the IMPORTANT-COMMENT-REGARDING-FILTERS-AND-DIRECT-CHILDREN-BEHAVIOUR above
      # to understand why we regard all visible_tree_leaves_changes as parents, and one
      # level above it as direct parent, well.
      for parent_id of visible_tree_leaves_changes
        if parent_id of @_collection_items_tracked_for_filter_aware_descendants_changes
          announceTrackedItemChanged(parent_id, true) # true is for direct parent

      # Go up the tree, for every parent, check if it is in the
      # _collection_items_tracked_for_filter_aware_descendants_changes
      items_to_check = _.keys(visible_tree_leaves_changes)
      level = 0
      while (not _.isEmpty(parents_docs = self._grid_data._grid_data_core.getAllDirectParentsItemsDocs(items_to_check)))
        level += 1

        items_to_check = []

        for parent_doc in parents_docs
          if parent_doc._id of @_collection_items_tracked_for_filter_aware_descendants_changes
            announceTrackedItemChanged(parent_doc._id, level <= 1) # level <= 1 is to mark whether it is a direct parent. Read the IMPORTANT-COMMENT-REGARDING-FILTERS-AND-DIRECT-CHILDREN-BEHAVIOUR above to learn more about <= 1 is regarded as direct parent

          items_to_check.push parent_doc._id

      return

    return

  invalidateOnCollectionItemDescendantsChanges: (collection_item_id, options) ->
    # If the filter_aware option is false, this method acts as a simple proxy to
    # GridDataCore's @invalidateOnCollectionItemDescendantsChanges.
    #
    # Search this document for IMPORTANT-COMMENT-REGARDING-FILTERS-AND-DIRECT-CHILDREN-BEHAVIOUR

    if not Tracker.currentComputation?
      console.error "invalidateOnCollectionItemDescendantsChanges must be called inside a computation"

      return

    default_options =
      direct_children_only: false
      filters_aware: false # If set to true, changes to the collection item's descendants filter-passing
                           # state will also trigger invalidation. Behaviour is tricky, read more by seraching
                           # this file for: IMPORTANT-COMMENT-REGARDING-FILTERS-AND-DIRECT-CHILDREN-BEHAVIOUR
      tracked_fields: undefined # Usage example for direct_children_only: ["title", "status"]
                                #
                                # Note, structure changes (add/remove parent) are considered
                                # as changing all the fields, so even if option is set to
                                # ["title", "status"] , add child to the tracked
                                # collection_item_id will still trigger invalidation.
    options = _.extend default_options, options

    # We always begin from proxying the call to GridDataCore's @invalidateOnCollectionItemDescendantsChanges
    # to handle all the non-filter-aware related tracking. GridDataCore isn't aware of filters which are
    # defined in the grid-control level.

    # Note, that GridDataCore's invalidateOnCollectionItemDescendantsChanges takes responsibility to
    # destroy its trackers upon current computation invalidation. So, for all the non-filter-aware
    # work we are done right here.
    @_grid_data._grid_data_core.invalidateOnCollectionItemDescendantsChanges(collection_item_id, {tracked_fields: options.tracked_fields, direct_children_only: options.direct_children_only})

    if not options.filters_aware
      return

    # if options.filters_aware is true we set the filter aware tracking.

    tracker_id = Random.id()
    tracker_dep = new Tracker.Dependency()

    tracker_dep.depend()

    tracker_def =
      tracker_id: tracker_id
      direct_children_only: options.direct_children_only or false
      tracked_fields: options.tracked_fields or undefined
      descendants_changed_dep: tracker_dep

    if not @_collection_items_tracked_for_filter_aware_descendants_changes[collection_item_id]?
      @_collection_items_tracked_for_filter_aware_descendants_changes[collection_item_id] = []
    @_collection_items_tracked_for_filter_aware_descendants_changes[collection_item_id].push tracker_def

    if Tracker.currentComputation?
      Tracker.onInvalidate =>
        # Once invalidated, remove the tracker.

        @_collection_items_tracked_for_filter_aware_descendants_changes[collection_item_id] =
          _.filter(@_collection_items_tracked_for_filter_aware_descendants_changes[collection_item_id], (_tracker_def) -> _tracker_def.tracker_id != tracker_id)

        if _.isEmpty(@_collection_items_tracked_for_filter_aware_descendants_changes[collection_item_id])
          delete @_collection_items_tracked_for_filter_aware_descendants_changes[collection_item_id]

        return


    return

  getViewportScrollTop: -> $(".slick-viewport", @container).scrollTop()
  setViewportScrollTop: (offset) -> $(".slick-viewport", @container).scrollTop(offset)

  getViewportScrollLeft: -> $(".slick-viewport", @container).scrollLeft()
  setViewportScrollLeft: (offset) -> $(".slick-viewport", @container).scrollLeft(offset)

  countTasks: (options) ->
    default_options =
      depth: undefined
      filtered_tree: true
      max_items: 1000

    options = _.extend default_options, options

    limit_reached = false
    tasks_count = 0
    @_grid_data.each "/", {filtered_tree: options.filtered_tree, expand_only: false}, (_1, _2, _3, path) =>
      path_level = GridData.helpers.getPathLevel(path)

      tasks_count += 1

      if tasks_count > options.max_items
        limit_reached = true

        return -2

      if options.depth? and path_level == options.depth
        return -1

      return

    return {tasks_count, limit_reached}

  expandDepth: (options) ->
    default_options =
      depth: undefined # undefined is unlimited
      filtered_tree: true
      max_items: 1000

    options = _.extend default_options, options

    if options.filtered_tree is false
      throw @_error "not-supported", "false options.filtered_tree isn't supported yet"

    if @countTasks(options).limit_reached
      JustdoSnackbar.show
        text: "Too many items to expand"

      return

    @_grid_data.expandPassedFilterPaths(options.depth)

    return

  restoreGridDataItemFieldValueFromCollection: (items_ids, fields_ids) ->
    # Revert the field value in the grid-data level to its value in the Collection level.
    #
    # For the original motivation to this function see the video under bug: Task #12001: Auto-manual-value formatter isn't behaving correctly when change is blocked by a collection hook

    if _.isString(items_ids)
      items_ids = [items_ids]

    if _.isString(fields_ids)
      fields_ids = [fields_ids]

    check items_ids, [String]
    check fields_ids, [String]

    # We keep this one as a separate cb, just to keep it inline with edit() under 
    # /Users/theosp/justdo/justdo-devops/nodes/justdo-web-app/justdo-web-app/modules/justdo.gridctrl/packages/grid-data/lib/grid-data/collection-operations/collection-operations.coffee
    # That we followed.
    edit_failed = (err) =>
      # XXX We used to think we need the following, now it seems
      # that following a code refactor it became redundant.
      # (was very hacky, so it's very good)
      #
      # See related topic: observeChanges doesn't revert failed edits
      # See: https://github.com/meteor/meteor/issues/4282
      # @_data_changes_queue.push ["update", [item_id, [col_field]]] # NEED REWRITE

      @_grid_data._set_need_flush()

      @_grid_data.emit "edit-failed", err

      return

    for item_id in items_ids
      update_request = {}

      for field_id in fields_ids
        update_request[field_id] = @collection.findOne(item_id, {fields: {[field_id]: 1}})?[field_id]

      @_grid_data._grid_data_core._data_changes_handlers.update.call(@_grid_data._grid_data_core, item_id, update_request)
      edit_failed(@_error "edit-blocked-by-hook", "Edit blocked by hook")

    return

  getRowNodeIndex: ($row) ->
    return @_grid.getRowFromNode($row.get(0).rowNode)

  getRowNode: (row_index) ->
    if not (row_node = @_grid.getRowNode(row_index).rowNode)?
      return undefined

    return $(row_node)

  getCollectionItemById: (item_id) ->
    return @_grid_data.items_by_id[item_id]