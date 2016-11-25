GridControl.installFormatter "datetimeFormatter",
  getDateTimeString: (value) ->
    if not value? or value == ""
      return ""

    return moment(value).format('L LTS')

  slick_grid: ->
    {value, formatter_obj} = @getFriendlyArgs()

    formatter = """
      <div class="grid-formatter datetime-formatter">#{formatter_obj.getDateTimeString(value)}</div>
    """

    return formatter

  print: (doc, field) ->
    {value, options, formatter_obj} = @getFriendlyArgs()

    return formatter_obj.getDateTimeString(value)
