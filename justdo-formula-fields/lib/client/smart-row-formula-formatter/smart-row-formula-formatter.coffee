#
# Smart Row Formula Formatter
#
# A client-side formula field that evaluates same-row formulas,
# including references to Smart Number (calculated) fields.
#
# Caching strategy (two layers):
#
# Layer 1 — Per-column compile cache (grid_control column data):
#   The formula string is identical for every row of the same column.
#   We cache the result of replaceFieldsWithSymbols + parseSingleRestrictedRationalExpression
#   + compile per column in grid_control._columns_data. This avoids re-parsing the
#   formula on every cell render. The cache is invalidated when the formula text
#   changes (detected by slickGridColumnStateMaintainer).
#
# Layer 2 — Per-row nested evaluation cache (sameTickCache):
#   When multiple smart row formula columns in the same row reference the same
#   nested smart row formula field, sameTickCache ensures each nested field is
#   evaluated at most once per render tick. The cache auto-clears at the end
#   of the JS tick (after the synchronous render completes).
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
          # Clear the compile cache so it gets rebuilt with the new formula
          @clearCurrentColumnData("srf_compiled")

          dep.changed()

        return

    Tracker.onInvalidate ->
      formula_watch_computation.stop()

    return

  # Get or build the compiled formula for a given field.
  # Returns {field_to_symbol, compiled} from cache if the formula hasn't changed,
  # otherwise parses, validates, and compiles, then caches the result.
  _getCompiledFormula: (grid_control, field, formula) ->
    cached = grid_control.getColumnData(field, "srf_compiled")

    if cached? and cached.formula is formula
      return cached

    {mathjs_formula, field_to_symbol} = APP.justdo_formula_fields.replaceFieldsWithSymbols(formula)
    parsed_formula = JustdoMathjs.parseSingleRestrictedRationalExpression(mathjs_formula)
    compiled = parsed_formula.compile()

    result = {formula, mathjs_formula, field_to_symbol, compiled}
    grid_control.setColumnData(field, "srf_compiled", result)

    return result

  getFieldValue: (friendly_args) ->
    {formatter_obj, grid_control, field, path, doc, schema, _evaluating_fields} = friendly_args

    # _evaluating_fields tracks which smart row formula fields are currently
    # being evaluated up the call stack, preventing infinite recursion from
    # circular dependencies (e.g., field A references field B which references field A).
    if not _evaluating_fields?
      _evaluating_fields = {}

    # Get formula from schema grid_column_formatter_options
    formatter_options = schema?.grid_column_formatter_options
    formula = formatter_options?.formula

    if not formula? or formula is ""
      return ""

    # Layer 1: Use per-column compile cache.
    # The formula is the same for every row of this column, so we avoid
    # re-parsing and re-compiling on each cell render.
    try
      {field_to_symbol, compiled} = formatter_obj._getCompiledFormula(grid_control, field, formula)
    catch e
      # Formula parse/compile error — return blank
      return ""

    # Collect field values
    field_values = {}
    has_error = false

    for field_id, symbol of field_to_symbol
      # Get field schema to check if it's a calculated field
      field_schema = grid_control.getFieldDef field_id

      value = null

      if field_schema?.grid_column_formatter is "calculatedFieldFormatter"
        # This is a Smart Number (calculated field) - use the calculated value getter
        calc_result = GridControl.Formatters.calculatedFieldFormatter.calculatePathCalculatedFieldValue(grid_control, field_id, path, doc)

        if calc_result?.err?
          # Error in calculated field
          has_error = true
          break

        if calc_result?.cval?
          value = calc_result.cval
        else if _.isNumber(calc_result) or _.isString(calc_result)
          value = calc_result
        else
          value = null
      else if field_schema?.grid_column_formatter is "smartRowFormulaFormatter"
        # This is another Smart Row Formula field - get its calculated value.
        # Pass _evaluating_fields to detect circular dependencies.
        nested_result = formatter_obj.evaluateFormula(grid_control, field_id, path, doc, _evaluating_fields)
        if nested_result?.error
          has_error = true
          break
        value = nested_result?.value
      else if _.isFunction(field_schema?.grid_column_manual_and_auto_values_getter)
        {manual_value, auto_value} = field_schema.grid_column_manual_and_auto_values_getter(doc)
        if manual_value?
          value = manual_value
        else
          value = auto_value
      else
        # Regular field - get raw value from document
        value = doc[field_id]

      field_values[field_id] = value

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

    # Prepare mathjs evaluation arguments
    mathjs_args = {}
    for field_id, symbol of field_to_symbol
      mathjs_args[symbol] = field_values[field_id]

    # Evaluate using the pre-compiled expression (Layer 1 cache).
    # Only compiled.evaluate() runs per cell — parse and compile are cached.
    try
      result = compiled.evaluate(mathjs_args)
    catch e
      # Evaluation error - return blank
      return ""

    if not _.isNumber(result) or _.isNaN(result)
      return ""

    return result

  # Helper method to evaluate a formula for a specific field.
  # Used for nested smart row formula references.
  #
  # The _evaluating_fields parameter is a set (object) of field IDs currently
  # being evaluated up the call stack. If field_id is already in the set,
  # we have a circular dependency and return an error to prevent infinite recursion.
  #
  # Layer 2: Results are cached in sameTickCache keyed by (field_id, path) so
  # that if multiple columns in the same row reference the same nested formula,
  # it is evaluated at most once per render tick.
  evaluateFormula: (grid_control, field_id, path, doc, _evaluating_fields) ->
    if not _evaluating_fields?
      _evaluating_fields = {}

    # Layer 2: Check per-row nested evaluation cache.
    # If this field was already evaluated for this row in the current tick,
    # return the cached result immediately.
    cache_key = "srf-eval::#{field_id}::#{path}"
    if JustdoHelpers.sameTickCacheExists(cache_key)
      return JustdoHelpers.sameTickCacheGet(cache_key)

    # Circular dependency guard: if this field is already being evaluated
    # up the call stack, bail out to prevent infinite recursion.
    # We intentionally do NOT cache this result — circular dependency detection
    # is call-chain-specific and the cache should only hold fully resolved values.
    if field_id of _evaluating_fields
      return {error: true}

    _evaluating_fields[field_id] = true

    field_schema = grid_control.getFieldDef field_id

    if not field_schema?
      return {error: true}

    formatter_options = field_schema?.grid_column_formatter_options
    formula = formatter_options?.formula

    if not formula? or formula is ""
      result = {value: null}
      JustdoHelpers.sameTickCacheSet(cache_key, result)
      return result

    # Create a minimal friendly_args for getFieldValue
    friendly_args =
      formatter_obj: @
      grid_control: grid_control
      field: field_id
      path: path
      doc: doc
      schema: field_schema
      _evaluating_fields: _evaluating_fields

    value = @getFieldValue(friendly_args)

    if value is ""
      result = {value: null}
    else
      result = {value: value}

    JustdoHelpers.sameTickCacheSet(cache_key, result)
    return result

  getHumanReadableFormulaAttribute: (field_id, grid_control) ->
    human_readable_formula = APP.justdo_formula_fields.getHumanReadableFormula field_id, grid_control
    if _.isEmpty(human_readable_formula)
      return ""

    human_readable_formula = JustdoHelpers.xssGuard human_readable_formula
    return " title=\"#{human_readable_formula}\""

  #
  # Formatters
  #
  slick_grid: ->
    friendly_args = @getFriendlyArgs()

    {formatter_obj, schema, field, grid_control} = friendly_args

    value = formatter_obj.getFieldValue(friendly_args)

    if value is ""
      return """<div class="grid-formatter smart-row-formula-formatter"></div>"""

    custom_color = ""
    if (grid_ranges = schema?.grid_ranges)?
      value_range = null
      for range_def in grid_ranges
        if not (range = range_def.range)?
          console.warn "A range definition without range property detected, this shouldn't happen, please check"
        else
          [min, max] = range

          if not min? and not max?
            value_range = range_def
          else if not min? and max >= value
            value_range = range_def
          else if not max? and min <= value
            value_range = range_def
          else if min <= value and max >= value
            value_range = range_def

          if value_range?
            break

      if value_range?
        if (bg_color = value_range.bg_color)?
          bg_color = JustdoHelpers.normalizeBgColor(bg_color)

          if bg_color != "transparent"
            custom_color += """background-color: #{bg_color}; color: #{JustdoHelpers.getFgColor(bg_color)};"""

    # Round to 2 decimal places
    value = JustdoHelpers.roundNumber value, 2

    human_readable_formula_attribute = formatter_obj.getHumanReadableFormulaAttribute field, grid_control

    return """
      <div class="grid-formatter smart-row-formula-formatter" #{if not _.isEmpty(custom_color) then "style=\"#{custom_color}\"" else ""} #{human_readable_formula_attribute}>
        <div class="jd-numeric-value" style="font-weight: bold; text-decoration: underline;">#{JustdoHelpers.localeAwareNumberRepresentation value}</div>
      </div>
    """

  print: (doc, field, path) ->
    friendly_args = @getFriendlyArgs()

    {formatter_obj, field, grid_control} = friendly_args

    value = formatter_obj.getFieldValue(friendly_args)

    if value is ""
      return ""

    value = JustdoHelpers.roundNumber value, 2

    human_readable_formula_attribute = formatter_obj.getHumanReadableFormulaAttribute field, grid_control

    return """<div class="jd-numeric-value" style="font-weight: bold; text-decoration: underline;" #{human_readable_formula_attribute}>#{JustdoHelpers.localeAwareNumberRepresentation value}</div>"""

  print_formatter_produce_html: true
