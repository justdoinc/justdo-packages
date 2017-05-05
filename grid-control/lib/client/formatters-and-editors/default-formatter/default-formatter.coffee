GridControl.installFormatter "defaultFormatter",
  slick_grid: ->
    {schema, value, self} = @getFriendlyArgs()

    if not value?
      value = ""

    value = self.xssGuard value

    if @options.allow_dynamic_row_height
      value = self.nl2br value

    formatter = """
      <div class="grid-formatter default-formatter">#{value}</div>
    """

    return formatter

  print: (doc, field) ->
    return @defaultPrintFormatter()