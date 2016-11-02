PACK.Formatters = {}
PACK.FormattersInit = {}
PACK.FormattersHelpers = {}

_.extend GridControl.prototype,
  _formatters: null
  _load_formatters: ->
    @_formatters = {}

    formatters_extended_context_properties =
      # Formatters' `this` is set by us to their GridControl
      # object.
      # We extend the GridControl object provided to each
      # formatter with the following methods that will be
      # available from the formatter `this`.

      # Note the @ for each method is the GridControl
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
          row: row
          cell: cell
          value: value
          grid_column_info: grid_column_info
          schema: schema
          data: data
          options: schema.grid_column_formatter_options or {}

          grid_control: @
          grid_data: @_grid_data
          slick_grid: @_grid

        return args

      getRealSchema: ->
        @collection.simpleSchema()._schema[column_id]

    for formatter_name, formatter of PACK.Formatters
      do (formatter_name, formatter) =>
        @_formatters[formatter_name] = =>
          # @ is the GridControl instance
          extended_grid_control_obj = Object.create(@)
          _.extend extended_grid_control_obj,
            {original_args: arguments},
            formatters_extended_context_properties

          return formatter.apply(extended_grid_control_obj, arguments)

  _init_formatters: ->
    for formatter_name, formatter of @_formatters
      if formatter_name of PACK.FormattersInit
        if PACK.FormattersInit[formatter_name]?
          PACK.FormattersInit[formatter_name].call(@)
