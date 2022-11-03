default_bg_color = JustdoHelpers.normalizeBgColor("#FFFFFF")

GridControl.installFormatter "MultiSelectFormatter",
  slick_grid: ->
    {schema, doc, path, value} = @getFriendlyArgs()

    output = []

    values = value

    if _.isArray(values) and values.length > 0
      for value in values
        if (grid_values = schema.grid_values)?
          text = grid_values[value]?.txt
          bg_color = grid_values[value]?.bg_color

        if not text?
          continue

        if not bg_color? or bg_color == "00000000"
          # Note will also affect cases where propertiesGenerator(tag) returned [] / [undefined, "x"]
          bg_color = default_bg_color
        else
          bg_color = "##{bg_color}"

        bg_color = JustdoHelpers.normalizeBgColor(bg_color)
        fg_color = JustdoHelpers.getFgColor(bg_color)

        custom_style = """ style="background-color: #{JustdoHelpers.xssGuard(bg_color)}; color: #{JustdoHelpers.xssGuard(fg_color)};" """

        output.push """
          <div class="tag-wrapper" #{custom_style}>#{JustdoHelpers.xssGuard(text)}</div>
        """

    return """<div class="grid-formatter tag-formatter">#{output.join(" ")}</div>"""

  print: ->
    {schema, doc, path, value} = @getFriendlyArgs()

    output = []

    values = value

    if _.isArray(values) and values.length > 0
      for value in values
        if (text = schema.grid_values?[value]?.txt)?
          output.push text

    return output.join ", "
