_.extend PACK.Formatters,
  datetimeFormatter: (row, cell, value, columnDef, dataContext) ->
    if not value? or value == ""
      date = ""
    else
      date = moment(value).format('L LTS')

    formatter = """
      <div class="grid-formatter datetime-formatter">#{date}</div>
    """

    return formatter
