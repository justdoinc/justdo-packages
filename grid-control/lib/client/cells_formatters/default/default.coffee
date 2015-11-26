_.extend PACK.Formatters,
  defaultFormatter: (row, cell, value, columnDef, dataContext) ->
    if not value?
      return ""
    else
      value = (value + "").replace(/&/g,"&amp;").replace(/</g,"&lt;").replace(/>/g,"&gt;")

      if @options.allow_dynamic_row_height
        value = value.replace(/\n/g, "<br>")