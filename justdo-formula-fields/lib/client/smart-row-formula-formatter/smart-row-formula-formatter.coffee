#
# Smart Row Formula Formatter
#
# A client-side formula field that evaluates same-row formulas,
# including references to Smart Number (calculated) fields.
#

formatter_name = "smartRowFormulaFormatter"
GridControl.installFormatter formatter_name,
  # Invalidate when any dependency field changes
  invalidate_on_dependencies_change: true

  slickGridColumnStateMaintainer: ->
    if not Tracker.active
      @logger.warn "slickGridColumnStateMaintainer: called outside of computation, skipping"

      return

    # Create a dependency and depend on it.
    dep = new Tracker.Dependency()
    dep.depend()

    formula_watch_computation = null
    Tracker.nonreactive =>
      # Run in an isolated reactivity scope
      formula_watch_computation = Tracker.autorun =>
        # Get the current formula from the schema (reactive via getSchemaExtendedWithCustomFields)
        extended_schema = @getSchemaExtendedWithCustomFields()
        field = @getColumnFieldId()
        schema = extended_schema[field]
        current_formula = schema?.grid_column_formatter_options?.formula

        cached_formula = @getCurrentColumnData("formula")

        if current_formula != cached_formula
          @setCurrentColumnData("formula", current_formula)

          dep.changed()

        return

    Tracker.onInvalidate ->
      formula_watch_computation.stop()

    return

  getFieldValue: (friendly_args) ->
    {formatter_obj, grid_control, field, path, doc, schema} = friendly_args

    # Get formula from schema grid_column_formatter_options
    formatter_options = schema?.grid_column_formatter_options
    formula = formatter_options?.formula

    if not formula? or formula is ""
      return ""

    # Use the shared regex from JustdoFormulaFields for extracting field placeholders
    field_component_regex = JustdoFormulaFields.formula_fields_components_matcher_regex

    # Collect all referenced fields and their values
    field_to_symbol = {}
    field_values = {}
    symbol_index = 0
    has_error = false

    # First pass: extract all field references and get their values
    formula.replace field_component_regex, (match, field_id) ->
      if field_id of field_to_symbol
        # Already processed this field
        return match

      field_to_symbol[field_id] = JustdoFormulaFields.symbols_indexes[symbol_index]
      symbol_index += 1

      # Get field schema to check if it's a calculated field
      field_schema = grid_control.getFieldDef field_id

      value = null

      if field_schema?.grid_column_formatter is "calculatedFieldFormatter"
        # This is a Smart Number (calculated field) - use the calculated value getter
        calc_result = GridControl.Formatters.calculatedFieldFormatter.calculatePathCalculatedFieldValue(grid_control, field_id, path, doc)

        if calc_result?.err?
          # Error in calculated field
          has_error = true
          return match

        if calc_result?.cval?
          value = calc_result.cval
        else if _.isNumber(calc_result) or _.isString(calc_result)
          value = calc_result
        else
          value = null
      else if field_schema?.grid_column_formatter is "smartRowFormulaFormatter"
        # This is another Smart Row Formula field - get its calculated value
        nested_result = formatter_obj.evaluateFormula(grid_control, field_id, path, doc)
        if nested_result?.error
          has_error = true
          return match
        value = nested_result?.value
      else
        # Regular field - get raw value from document
        value = doc[field_id]

      field_values[field_id] = value

      return match

    if has_error
      return ""

    # Check if all values are missing/empty, and convert values to numbers
    all_fields_empty = true
    for field_id, symbol of field_to_symbol
      value = field_values[field_id]

      if not value? or value is ""
        # Missing or empty value - treat as 0
        field_values[field_id] = 0
      else
        # At least one field has a value
        all_fields_empty = false

        if not _.isNumber(value)
          if _.isString(value)
            parsed = parseFloat(value)
            if _.isNaN(parsed)
              # Non-numeric string value - treat as 0
              field_values[field_id] = 0
            else
              field_values[field_id] = parsed
          else
            # Non-numeric value - treat as 0
            field_values[field_id] = 0

    # Only return blank if ALL dependent fields are empty
    if all_fields_empty
      return ""

    # Build the mathjs formula by replacing placeholders with symbols
    mathjs_formula = formula.replace field_component_regex, (match, field_id) ->
      return field_to_symbol[field_id]

    # Prepare mathjs evaluation arguments
    mathjs_args = {}
    for field_id, symbol of field_to_symbol
      mathjs_args[symbol] = field_values[field_id]

    # Evaluate the formula using mathjs
    try
      parsed_formula = JustdoMathjs.math.parse(mathjs_formula)
      compiled = parsed_formula.compile()
      result = compiled.evaluate(mathjs_args)
    catch e
      # Evaluation error - return blank
      return ""

    if not _.isNumber(result) or _.isNaN(result)
      return ""

    return result

  # Helper method to evaluate a formula for a specific field
  # Used for nested smart row formula references
  evaluateFormula: (grid_control, field_id, path, doc) ->
    field_schema = grid_control.getFieldDef field_id

    if not field_schema?
      return {error: true}

    formatter_options = field_schema?.grid_column_formatter_options
    formula = formatter_options?.formula

    if not formula? or formula is ""
      return {value: null}

    # Create a minimal friendly_args for getFieldValue
    friendly_args =
      formatter_obj: @
      grid_control: grid_control
      field: field_id
      path: path
      doc: doc
      schema: field_schema

    value = @getFieldValue(friendly_args)

    if value is ""
      return {value: null}

    return {value: value}

  #
  # Formatters
  #
  slick_grid: ->
    friendly_args = @getFriendlyArgs()

    {formatter_obj} = friendly_args

    value = formatter_obj.getFieldValue(friendly_args)

    if value is ""
      return """<div class="grid-formatter smart-row-formula-formatter"></div>"""

    # Round to 2 decimal places
    value = JustdoHelpers.roundNumber value, 2

    style_right = APP.justdo_i18n.getRtlAwareDirection "right"

    return """
      <div class="grid-formatter smart-row-formula-formatter">
        <div style="font-weight: bold; text-decoration: underline; text-align: #{style_right};">#{JustdoHelpers.localeAwareNumberRepresentation value}</div>
      </div>
    """

  print: (doc, field, path) ->
    friendly_args = @getFriendlyArgs()

    {formatter_obj} = friendly_args

    value = formatter_obj.getFieldValue(friendly_args)

    if value is ""
      return ""

    value = JustdoHelpers.roundNumber value, 2

    style_right = APP.justdo_i18n.getRtlAwareDirection "left"

    return """<div style="font-weight: bold; text-decoration: underline; text-align: #{style_right}; direction: ltr;">#{JustdoHelpers.localeAwareNumberRepresentation value}</div>"""

  print_formatter_produce_html: true
