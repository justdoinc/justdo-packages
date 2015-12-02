_.extend PACK.Formatters,
  unicodeDateFormatter: (row, cell, value, columnDef, dataContext) ->
    if not value?
      date = ""
    else
      date = moment(new Date(value)).format('YYYY-MM-DD')

    formatter = """
      <div class="grid-formatter uni-date-formatter">#{date}</div>
    """

    return formatter