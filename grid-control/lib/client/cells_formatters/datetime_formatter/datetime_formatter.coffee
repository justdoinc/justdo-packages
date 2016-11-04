getDateTimeString = (value) ->
  if not value? or value == ""
    return ""

  return moment(value).format('L LTS')

_.extend PACK.Formatters,
  datetimeFormatter:
    slick_grid: (row, cell, value, columnDef, dataContext) ->
      {value} = @getFriendlyArgs()

      formatter = """
        <div class="grid-formatter datetime-formatter">#{getDateTimeString(value)}</div>
      """

      return formatter

    print: (doc, field) ->
      {value, options} = @getFriendlyArgs()

      return getDateTimeString(value)
