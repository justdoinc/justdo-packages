helpers = PACK.FormattersHelpers

_.extend PACK.Formatters,
  defaultFormatter: (row, cell, value, columnDef, dataContext) ->
    if not value?
      return ""

    value = helpers.xssGuard value

    if @options.allow_dynamic_row_height
      value = helpers.nl2br value

    formatter = """
      <div class="grid-formatter default-formatter">#{value}</div>
    """

    return formatter