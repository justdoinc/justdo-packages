helpers = PACK.FormattersHelpers

_.extend PACK.Formatters,
  keyValueFormatter: (row, cell, key, columnDef, dataContext) ->
    options = {}
    if columnDef.values != null
      options = columnDef.values

    if not key?
      key = ""

    value = ""
    if not options[key]?
      value = key
    else if options[key].html?
      value = options[key].html
    else
      value = options[key].txt

    # XXX IMPORTANT: No XSS protection, if values can be modified
    # by user XSS protection must be added.

    formatter = """
      <div class="grid-formatter key-val-formatter">#{value}</div>
    """

    return formatter