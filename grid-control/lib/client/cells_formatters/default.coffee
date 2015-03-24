_.extend PACK.Formatters,
  defaultFormatter: (row, cell, value, columnDef, dataContext) ->
    if not value?
      return ""
    else
      return (value + "").replace(/&/g,"&amp;").replace(/</g,"&lt;").replace(/>/g,"&gt;")
