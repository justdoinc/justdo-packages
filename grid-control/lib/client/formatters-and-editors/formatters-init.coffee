PACK.Formatters = {}

GridControl.Formatters = PACK.Formatters

#
# Formatters installers/getters
#

# IMPORTANT, you must install formatters before initiating the grid
# control object in order for them to be available under it.
# Might change in the future.
GridControl.installFormatter = (formatter_name, formatter_definition) ->
  return PACK.Formatters[formatter_name] = formatter_definition

GridControl.installFormatterExtension = (options) ->
  check options, {
    formatter_name: String
    extended_formatter_name: String
    custom_properties: Object
  }

  {
    formatter_name
    extended_formatter_name
    custom_properties
  } = options

  if not (parent_formatter = GridControl.getFormatters()[extended_formatter_name])?
    throw Meteor.Error "unknown-formatter", "Formatter #{extended_formatter_name} doesn't exist"

  new_formatter = Object.create(parent_formatter)

  # Leave reference to the extended formatter
  _.extend new_formatter, custom_properties,
    extended_formatter_name: extended_formatter_name

  # Leave references to the extended formatter that began
  # the extensions chain
  if not new_formatter.original_extended_formatter_name?
    new_formatter.original_extended_formatter_name =
      extended_formatter_name

  GridControl.installFormatter formatter_name, new_formatter

  return 

GridControl.getFormatters = ->
  # Return all the installed formatters_definitions
  return PACK.Formatters

#
# Formatters loaders
#
_.extend GridControl.prototype,
  _formatters: null
  _columns_state_maintainers = null
  _tree_control_fomatters: null
  _print_formatters: null

  _loaded_slick_grid_jquery_events = null
  # Formatters' slick_grid_jquery_events should be loaded only once.
  #
  # If a formatter is inheriting from another formatter that has
  # slick_grid_jquery_events without changing it, we don't want to
  # load it again, to prevent that, we use
  # @_loaded_slick_grid_jquery_events to keep track on the events arrays
  # we've loaded already, .

  _load_formatters: ->
    #
    # Load all the formatters for the current grid_control object
    #

    # the SlickGrid formatters, called simply _formatters for historical
    # reasons
    @_formatters = {}
    # Each formatter type can define a column state maintainer (see
    # slickGridColumnStateMaintainer below). The state maintainer is a reactive
    # resource that upon invalidation will trigger recalculation of the entire
    # column
    @_columns_state_maintainers = {}
    @_tree_control_fomatters = []
    @_print_formatters = {}
    @_loaded_slick_grid_jquery_events = []

    for formatter_name, formatter_definition of PACK.Formatters
      @loadFormatter(formatter_name, formatter_definition)

    return

  loadFormatter: (formatter_name, formatter_definition) ->
    # Load formatters definitions.
    #
    # Arguments:
    # ----------
    #
    # formatter_name: the name used to refer the formatter generated
    # data structures.
    #
    # formatter_definition structure:
    #
    #   {
    #     slick_grid: the slick grid formatter
    #                 Read below about the @_formatters[formatter_name]
    #                 we generate based on slick_grid to learn more.
    #     slickGridColumnStateMaintainer: Optional, a reactive resource that upon invalidation
    #                                     will trigger recalculation of all columns that uses
    #                                     this formatter.
    #     is_slick_grid_tree_control_formatter: set to true if this formatter has
    #                                           tree control controls in its slick_grid
    #                                           formatter, otherwise set to false or don't
    #                                           set (false is default value)
    #     slick_grid_jquery_events: If defined, should be an array of objects in the format described
    #                               in /jquery_events/init.coffee for installCustomJqueryEvent()
    #                               If a formatter inherit from another formatter and doesn't change
    #                               slick_grid_jquery_events, we won't load the events another time
    #                               check @_loaded_slick_grid_jquery_events's comment above for more details.
    #
    #     invalidate_ancestors_on_change: Can be set to: "off" / "structure-and-content" / "structure-content-and-filters"
    #                                     Is "off" by default.
    #                                     If set to "structure-and-content", changes to items content, and tree structure changes,
    #                                     will trigger invalidation (recalculation) of ancestors of the affected rows.
    #                                     If set to "structure-content-and-filters", tree structure changes resulted from filters
    #                                     will also trigger invalidation of ancestors of the affected rows.
    #
    #     gridControlInit: will be called once the "init" event
    #                      of the grid control will be fired,
    #                      that's the place to perform inits required
    #                      by this formatter that should be done only
    #                      once.
    #                      `this` is the (regular, no-extensions) grid control instance.
    #
    #     print: the print formatter
    #            Read below about the @_print_formatters[formatter_name]
    #            we generate based on slick_grid to learn more.
    #
    #     Any other properties set here will be accessible from the generated
    #     @_formatters[formatter_name] and @_print_formatters[formatter_name]
    #     by calling inside them: @getFriendlyArgs() -> the returned object
    #     will have formatter_obj referencing to this object.
    #   }
    #
    # loadFormatter does the following:
    # ---------------------------------
    #
    # 1. If formatter_definition.gridControlInit exists:
    # Setting up the event that calls it.
    # 
    # 2. If, is_slick_grid_tree_control_formatter is true, add
    # formatter_name to @_tree_control_fomatters
    #
    # 3. If slick_grid_jquery_events is set, install the events
    #    defined under it using @installCustomJqueryEvent()
    #
    # 4. Creates the formatters functions:
    #
    # * @_formatters[formatter_name]:
    # 
    # This function is called by SlickGrid to generate the cell
    # content for cells of the specified formatter_name.
    #
    # This function calls formatter_definition.slick_grid with `this` as
    # an object that inherits from GridControl and extends it
    # with the following properties:
    # {
    #    original_args: the original arguments SlickGrid called the formatter function with
    #    formatter_name: the formatter_name given above.
    #    all the properties under: common_formatters_helpers below
    #    all the properties under: slick_grid_formatters_extended_context_properties
    # }
    #
    # * @_print_formatters[formatter_name]:
    #
    # This function calls formatter_definition.print with `this`
    # just like described in @_formatters[formatter_name] but instead of 
    # slick_grid_formatters_extended_context_properties we extend the
    # GridControl-instance-inherited object with: print_formatters_extended_context_properties
    #
    # 5. Create the grid control columns state maintainers for each formatter:
    #
    # * @_columns_state_maintainers[formatter_name]
    #
    # This function is called by the JustDo grid control inside a computation
    # that is created upon the grid control init for each row in the view that uses 
    # formatter_name.
    #
    # The computation is stopped and recreated on every change to the grid columns (the
    # grid view), and stopped without replacement on grid destroy.
    #
    # The state maintainer is expected to be a reactive resource that invalidates when
    # a recalculation of the entire column that uses its formatter is required.
    #
    # We set @_columns_state_maintainers[formatter_name] only for the formatters
    # that has the slickGridColumnStateMaintainer option set.
    if not (slick_grid_formatter = formatter_definition.slick_grid)?
      throw @_error "invalid-formatter-definition", "Formatter `#{formatter_name}' doesn't define the slick grid formatter under its .slick_grid property"

    if not (print_formatter = formatter_definition.print)?
      throw @_error "invalid-formatter-definition", "Formatter `#{formatter_name}' doesn't define the print formatter under its .print property"

    @_formatters[formatter_name] = (...args) =>
      # @ is the GridControl instance
      extended_grid_control_obj = Object.create(@)
      _.extend extended_grid_control_obj,
        {original_args: args, original_gc: @, formatter_name: formatter_name},
        common_formatters_helpers,
        slick_grid_formatters_extended_context_properties

      return slick_grid_formatter.apply(extended_grid_control_obj, args)

    if (slickGridColumnStateMaintainer = formatter_definition.slickGridColumnStateMaintainer)?
      # We set _columns_state_maintainers for formatter only if slickGridColumnStateMaintainer
      # is defined for it
      @_columns_state_maintainers[formatter_name] = (...args) =>
        # @ is the GridControl instance
        extended_grid_control_obj = Object.create(@)
        _.extend extended_grid_control_obj,
          {original_args: args, original_gc: @, formatter_name: formatter_name},
          common_formatters_helpers,
          slick_grid_columns_state_maintainers_extended_context_properties

        return slickGridColumnStateMaintainer.apply(extended_grid_control_obj, args)


    @_print_formatters[formatter_name] = (...args) =>
      # @ is the GridControl instance
      extended_grid_control_obj = Object.create(@)
      _.extend extended_grid_control_obj,
        {original_args: args, original_gc: @, formatter_name: formatter_name},
        common_formatters_helpers,
        print_formatters_extended_context_properties

      return print_formatter.apply(extended_grid_control_obj, args)

    if formatter_definition.is_slick_grid_tree_control_formatter
      @_tree_control_fomatters.push formatter_name

    if _.isArray (formatter_slick_grid_jquery_events = formatter_definition.slick_grid_jquery_events)
      if not (formatter_slick_grid_jquery_events in @_loaded_slick_grid_jquery_events)
        # Don't load the formatter jquery events, if we loaded them already (can happen
        # in inherited formatters)
        # Read comment about @_loaded_slick_grid_jquery_events next to its
        # definition above for more details
        @_loaded_slick_grid_jquery_events.push(formatter_slick_grid_jquery_events)

        for event_definition in formatter_slick_grid_jquery_events
          @installCustomJqueryEvent(event_definition)

    pending_rebuild_or_tree_filter_updated_updates_arrays = []
    executePendingRebuildOrTreeFilterUpdatedUpdates = =>
      if pending_rebuild_or_tree_filter_updated_updates_arrays.length > 0
        # If anything remains in the buffer, execute and init the buffer
        @_invalidateItemAncestorsFieldsOfFormatterType(pending_rebuild_or_tree_filter_updated_updates_arrays, formatter_name, {update_self: true})

        pending_rebuild_or_tree_filter_updated_updates_arrays = [] # init

      return

    handleRebuildOrTreeFilterUpdatedUpdates = (items_pending_update_array) =>
      # When a tree structure change occur, it is likely that we'll get on the same
      # JS tick the both the 'grid-tree-filter-updated' and the 'rebuild_ready'
      # event. We use handleRebuildOrTreeFilterUpdatedUpdates() to buffer
      # them both to execute all the changes at once.
      pending_rebuild_or_tree_filter_updated_updates_arrays.push items_pending_update_array

      Meteor.defer =>
        executePendingRebuildOrTreeFilterUpdatedUpdates()

        return

      return

    if formatter_definition.invalidate_ancestors_on_change == "structure-content-and-filters"
      @on "grid-tree-filter-updated", (data) =>
        if not _.isEmpty (visible_tree_leaves_changes = data.visible_tree_leaves_changes)
          handleRebuildOrTreeFilterUpdatedUpdates(_.keys(visible_tree_leaves_changes))

        return

    if formatter_definition.invalidate_ancestors_on_change in ["structure-and-content", "structure-content-and-filters"]
      @once "init", =>
        # keep reference to _grid_data_core as by the time grid_control
        # is destroyed, the reference to _grid_data will be removed from
        # it.
        grid_data_core = @_grid_data._grid_data_core

        @on "rebuild_ready", (data) =>
          if not _.isEmpty (items_ids_with_changed_children = data.items_ids_with_changed_children)
            handleRebuildOrTreeFilterUpdatedUpdates(_.keys(items_ids_with_changed_children))

          return

        # Keep track of content changes
        content_changed_cb = (item_id, changed_fields_array) =>
          @_invalidateItemAncestorsFieldsOfFormatterType(item_id, formatter_name, {changed_fields_array})

          return

        grid_data_core.on "content-changed", content_changed_cb

        @once "destroyed", ->
          # Remove the content-changed listener, note that this is important
          # since multiple tabs in grid-control-mux shares the same grid-data-core
          # so when a tab is unloaded we don't want its event to keep living  
          grid_data_core.removeListener "content-changed", content_changed_cb
          grid_data_core = null

          return

    if _.isFunction(grid_control_init = formatter_definition.gridControlInit)
      @once "init", =>
        grid_control_init.call(@)

    return

common_formatters_helpers =
  nl2br: (text) -> text.replace(/\n/g, "<br>")

  xssGuard: (text) -> JustdoHelpers.xssGuard(text)

  getColumnFieldId: ->
    friendly_args = @getFriendlyArgs()

    return friendly_args.field

  setCurrentColumnData: (key, val) ->
    return @setColumnData(@getColumnFieldId(), key, val)

  clearCurrentColumnData: (key) ->
    friendly_args = @getFriendlyArgs()

    return @clearColumnData(@getColumnFieldId(), key)

  getCurrentColumnData: (key) ->
    friendly_args = @getFriendlyArgs()

    return @getColumnData(@getColumnFieldId(), key)

slick_grid_formatters_extended_context_properties =
  # Note the @ for each method is the GridControl-instance-inherited formatter
  # object created in the loadFormatter proccess for each formatter.
  # Read more in loadFormatter comment

  getFriendlyArgs: ->
    # Returns an object with the arguments
    # passed to the formatter and other commonly needed resources
    # (such as schema).
    # That object will also include `options`
    # property with the field's grid_column_formatter_options or
    # empty object if grid_column_formatter_options weren't defined.

    [row, cell] = @original_args

    friendly_args = @getFriendlyCellArgs(row, cell)

    friendly_args.original_grid_control = @original_gc # note isn't the same as friendly_args.self !
    friendly_args.options = friendly_args.formatter_options # For backward compatibility.

    return friendly_args

  getRealSchema: ->
    return @collection.simpleSchema()._schema[@original_args[3].id]

slick_grid_columns_state_maintainers_extended_context_properties =
  # Note the @ for each method is the GridControl-instance-inherited formatter
  # object created in the loadFormatter proccess for each formatter.
  # Read more in loadFormatter comment

  getFriendlyArgs: ->
    # Returns an object with the arguments
    # passed to the formatter and other commonly needed resources
    # (such as schema).
    # That object will also include `options`
    # property with the field's grid_column_formatter_options or
    # empty object if grid_column_formatter_options weren't defined.

    [{column_id}] = @original_args

    field = column_id # at the moment field and column_id are interchangable,
                      # in the future if it won't be the case, we'll need
                      # to update the apis.

    extended_schema = @getSchemaExtendedWithCustomFields()
    schema = extended_schema[field]

    args =
      # See notes on self in slick_grid_formatters_extended_context_properties
      self: @

      field: field

      schema: schema

      original_grid_control: @original_gc

      grid_control: @
      grid_data: @_grid_data
      slick_grid: @_grid

      formatter_name: @formatter_name
      # Read comment about formatter_obj in regular formatter's
      # getFriendlyArgs
      formatter_obj: PACK.Formatters[@formatter_name]

    return args

  getRealSchema: ->
    return @collection.simpleSchema()._schema[@original_args[3].id]

print_formatters_extended_context_properties =
  # Note the @ for each method is the GridControl-instance-inherited
  # print formatter object created in the loadFormatter proccess for
  # each print formatter. Read more in loadFormatter comment

  getFriendlyArgs: ->
    # Returns an object with the arguments
    # passed to the formatter and other commonly needed resources
    # (such as schema).
    # That object will also include `options`
    # property with the field's grid_column_formatter_options or
    # empty object if grid_column_formatter_options weren't defined.

    [doc, field, path] = @original_args

    schema = @getSchemaExtendedWithCustomFields()[field]

    args =
      # See notes on self in slick_grid_formatters_extended_context_properties
      self: @

      doc: doc
      field: field
      value: doc[field]
      path: path

      options: schema?.grid_column_formatter_options or {}

      schema: schema

      original_grid_control: @original_gc

      grid_control: @
      grid_data: @_grid_data
      slick_grid: @_grid

      formatter_name: @formatter_name
      # Read comment about formatter_obj in regular formatter's
      # getFriendlyArgs
      formatter_obj: PACK.Formatters[@formatter_name]

    return args

  getRealSchema: ->
    return @collection.simpleSchema()._schema[@original_args[1]]

  defaultPrintFormatter: ->
    {value} = @getFriendlyArgs()

    if _.isNumber value
      return "" + value

    return value