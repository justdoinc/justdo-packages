_.extend PACK.Formatters,
  unicodeDateFormatter: ->
    {value, options} = @getFriendlyArgs()

    if not value? or value == ""
      date = ""
    else
      date = moment(value, 'YYYY-MM-DD').format('YYYY-MM-DD')

    formatter = """
      <div class="grid-formatter uni-date-formatter">#{date}</div>
    """

    return formatter