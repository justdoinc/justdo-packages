_.extend PACK.Formatters,
  keyValueFormatter: (row, cell, value, columnDef, dataContext) ->
    options = {}
    if columnDef.values != null
      options = columnDef.values;

      if _.isFunction options
        options = options(@)

    if not value?
      value = ""

    return if options[value]? then options[value] else value
