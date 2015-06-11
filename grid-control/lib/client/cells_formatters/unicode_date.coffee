_.extend PACK.Formatters,
  unicodeDateFormatter: (row, cell, value, columnDef, dataContext) ->
    if not value?
      return ""
    return moment(new Date(value)).format('YYYY-MM-DD')