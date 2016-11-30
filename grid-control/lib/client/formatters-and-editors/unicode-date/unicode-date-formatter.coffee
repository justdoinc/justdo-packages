GridControl.installFormatter "unicodeDateFormatter",
  #
  # Helpers:
  # accessible through the 'formatter_obj' of the object returned
  # by @getFriendlyArgs()
  #
  normalizeUnicodeDateString: (unicode_date_string) ->
    if not unicode_date_string? or unicode_date_string == ""
      return ""

    return moment(unicode_date_string, 'YYYY-MM-DD').format('YYYY-MM-DD')

  #
  # Formatters
  #
  slick_grid: ->
    {formatter_obj, value} = @getFriendlyArgs()

    unicode_date_string =
      formatter_obj.normalizeUnicodeDateString(value)

    formatter_content = ""
    if unicode_date_string != ""
      formatter_content += """
        #{unicode_date_string}
      """

    formatter = """
      <div class="grid-formatter uni-date-formatter">
        #{formatter_content}
      </div>
    """

    return formatter

  print: (doc, field) ->
    {formatter_obj, value} = @getFriendlyArgs()

    return formatter_obj.normalizeUnicodeDateString(value)
