# XXX IMPORTANT: No XSS protection, if values can be modified
# by user XSS protection must be added.

getKeyValue = (schema, value, preferred_format="html") ->
  {grid_values, grid_removed_values} = schema

  if not grid_values?
    grid_values = {}

  if not grid_removed_values?
    grid_removed_values = {}

  if not value?
    # Regard undefined value as empty string (we don't return immediately to
    # allow the user set a html/txt labels for empty/undefined values)
    value = ""

  if not (value_by_formats = grid_values[value])?
    # Try look for the value in grid_removed_values
    if not (value_by_formats = grid_removed_values[value])?
      return value

  if (html_format = value_by_formats[preferred_format])?
    return html_format
  else if (txt_format = value_by_formats.txt)?
    return txt_format
  else
    return value

getKeyBgColor = (schema, value) ->
  {grid_values, grid_removed_values} = schema

  if not grid_values?
    grid_values = {}

  if not grid_removed_values?
    grid_removed_values = {}

  if not value?
    # Regard undefined value as empty string (we don't return immediately to
    # allow the user set a html/txt labels for empty/undefined values)
    return undefined

  if not (value_def = grid_values[value])?
    # Try look for the value in grid_removed_values
    if not (value_def = grid_removed_values[value])?
      return undefined

  return value_def.bg_color

GridControl.installFormatter "keyValueFormatter",
  slick_grid: ->
    {schema, value} = @getFriendlyArgs()

    bg_color = JustdoHelpers.normalizeBgColor(getKeyBgColor(schema, value))

    if bg_color != "transparent"
      custom_style = """ style="background-color: #{JustdoHelpers.xssGuard(bg_color)}; color: #{JustdoHelpers.xssGuard(JustdoHelpers.getFgColor(bg_color))};" """
    else
      custom_style = ''

    formatter = """
      <div class="grid-formatter key-val-formatter" #{custom_style}>
        #{JustdoHelpers.xssGuard(getKeyValue(schema, value), {allow_html_parsing: true, enclosing_char: ''})}
      </div>
    """

    return formatter

  print: (doc, field, path) ->
    {schema, value} = @getFriendlyArgs()

    return getKeyValue(schema, value, "print")
