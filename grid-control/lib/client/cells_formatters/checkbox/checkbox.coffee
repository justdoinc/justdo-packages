_.extend PACK.Formatters,
  checkboxFormatter: (row, cell, value, columnDef, dataContext) ->
    input = '<input type="checkbox" class="checkbox-formatter" name="' + value + '" value="' + value + '"'

    if value
      return input += ' checked />'

    return input += ' />'