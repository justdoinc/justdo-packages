PACK.Formatters = {}

#
# Formatters installers/getters
#

# IMPORTANT, you must install formatters before initiating the grid
# control object in order for them to be available under it.
# Might change in the future.
GridControl.installFormatter = (formatter_name, formatter_definition) ->
  return PACK.Formatters[formatter_name] = formatter_definition

GridControl.getFormatters = ->
  # Return all the installed formatters_definitions
  return PACK.Formatters

#
# Formatters loaders
#
_.extend GridControl.prototype,
  _formatters: null
  _tree_control_fomatters: null
  _print_formatters: null

  _load_formatters: ->
    #
    # Load all the formatters for the current grid_control object
    #

    @_formatters = {} # the SlickGrid formatters, called simply _formatters for historical reasons
    @_tree_control_fomatters = []
    @_print_formatters = {}

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
    #     is_slick_grid_tree_control_formatter: set to true if this formatter has
    #                                           tree control controls in its slick_grid
    #                                           formatter, otherwise set to false or don't
    #                                           set (false is default value)
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
    # 3. Creates the formatters functions:
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
    if not (slick_grid_formatter = formatter_definition.slick_grid)?
      throw @_error "invalid-formatter-definition", "Formatter `#{formatter_name}' doesn't define the slick grid formatter under its .slick_grid property"

    if not (print_formatter = formatter_definition.print)?
      throw @_error "invalid-formatter-definition", "Formatter `#{formatter_name}' doesn't define the print formatter under its .print property"

    @_formatters[formatter_name] = =>
      # @ is the GridControl instance
      extended_grid_control_obj = Object.create(@)
      _.extend extended_grid_control_obj,
        {original_args: arguments, formatter_name: formatter_name},
        common_formatters_helpers,
        slick_grid_formatters_extended_context_properties

      return slick_grid_formatter.apply(extended_grid_control_obj, arguments)

    @_print_formatters[formatter_name] = =>
      # @ is the GridControl instance
      extended_grid_control_obj = Object.create(@)
      _.extend extended_grid_control_obj,
        {original_args: arguments, formatter_name: formatter_name},
        common_formatters_helpers,
        print_formatters_extended_context_properties

      return print_formatter.apply(extended_grid_control_obj, arguments)

    if formatter_definition.is_slick_grid_tree_control_formatter
      @_tree_control_fomatters.push formatter_name

    if _.isFunction(grid_control_init = formatter_definition.gridControlInit)
      @once "init", =>
        grid_control_init.call(@)

    return

common_formatters_helpers =
  nl2br: (text) -> text.replace(/\n/g, "<br>")

  # We use very simple xssGuard due to the need for formatters to
  # run very fast (they can be called thusands of time on each build...)
  xssGuard: (text) -> (text + "").replace(/&/g,"&amp;").replace(/</g,"&lt;").replace(/>/g,"&gt;")

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

    [row, cell, value, grid_column_info, data] = @original_args

    column_id = grid_column_info.id
    schema = @schema[column_id]

    args =
      self: @
      # We added self, in additional to the slick_grid reference below
      # as it might be easier to explain formatters developers that
      # the special formatters helpers assigned during init process
      # are accessible through self instead of explaining the real
      # inheritance nature of formatters objects

      row: row
      cell: cell
      value: value
      field: column_id
      grid_column_info: grid_column_info
      schema: schema
      doc: data
      options: schema.grid_column_formatter_options or {}

      grid_control: @
      grid_data: @_grid_data
      slick_grid: @_grid

      formatter_name: @formatter_name
      # With formatter_obj referencing to the original formatter object we
      # can access helper methods attached to that object. It is useful not
      # only to keep orginzation but to allow formatters
      # inheritence (see unicode_date as a usage example)
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

    [doc, field] = @original_args

    schema = @schema[field]

    args =
      # See notes on self in slick_grid_formatters_extended_context_properties
      self: @

      doc: doc
      field: field
      value: doc[field]

      options: schema.grid_column_formatter_options or {}

      schema: schema

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

    return value