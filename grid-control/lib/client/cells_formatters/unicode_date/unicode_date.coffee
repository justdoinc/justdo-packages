normalizeUnicodeDateString = (unicode_date_string) ->
  if not unicode_date_string? or unicode_date_string == ""
    return ""

  return moment(unicode_date_string, 'YYYY-MM-DD').format('YYYY-MM-DD')


_.extend PACK.Formatters,
  unicodeDateFormatter:
    slick_grid: ->
      {value} = @getFriendlyArgs()

      formatter = """
        <div class="grid-formatter uni-date-formatter">#{normalizeUnicodeDateString(value)}</div>
      """

      return formatter

    print: (doc, field) ->
      {value} = @getFriendlyArgs()

      return normalizeUnicodeDateString(value)
