helpers = PACK.FormattersHelpers

# XXX IMPORTANT: No XSS protection, if values can be modified
# by user XSS protection must be added.

getKeyValue = (schema, value, preferred_format="html") ->
  {grid_values} = schema

  if not grid_values?
    grid_values = {}

  if not value?
    return ""

  if not (value_by_formats = grid_values[value])?
    return value

  if (html_format = value_by_formats[preferred_format])?
    return html_format
  else if (txt_format = value_by_formats.txt)?
    return txt_format
  else
    return value

_.extend PACK.Formatters,
  keyValueFormatter:
    slick_grid: ->
      {schema, value} = @getFriendlyArgs()

      formatter = """
        <div class="grid-formatter key-val-formatter">
          #{getKeyValue(schema, value)}
        </div>
      """

      return formatter

    print: (doc, field) ->
      {schema, value} = @getFriendlyArgs()

      return getKeyValue(schema, value, "print")
