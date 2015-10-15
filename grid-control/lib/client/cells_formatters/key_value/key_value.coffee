_.extend PACK.Formatters,
  keyValueFormatter: (row, cell, value, columnDef, dataContext) ->
    options = {}
    if columnDef.values != null
      options = columnDef.values;

    if not value?
      value = ""

    if not options[value]?
      return value

    if options[value].html?
      return options[value].html

    return options[value].txt
