formatDecimals = (decimal) ->
  if not decimal?
    return ""

  return JustdoMathjs.math.format(decimal, {precision: 2, notation: "fixed"}).replace(/\.0+$/, "")

GridControl.installFormatter "defaultFormatter",
  slick_grid: ->
    {schema, value, self} = @getFriendlyArgs()

    if not value?
      value = ""
    else
      # Only if we got value!
      if schema.type is Number and schema.decimal is true
        value = formatDecimals(value)

    value = self.xssGuard value

    if @options.allow_dynamic_row_height
      value = self.nl2br value

    formatter = """
      <div class="grid-formatter default-formatter">#{value}</div>
    """

    return formatter

  print: (doc, field, path) ->
    {value, schema} = @getFriendlyArgs()

    if schema.type is Number and schema.decimal is true
      return formatDecimals(value)

    if _.isNumber value
      return "" + value

    return value