default_bg_color = JustdoHelpers.normalizeBgColor("#FFFFFF")

GridControl.installFormatter "MultiSelectFormatter",
  slick_grid: ->
    {schema, doc, path, value} = @getFriendlyArgs()

    {grid_values, grid_removed_values} = schema

    if not grid_values?
      grid_values = {}

    if not grid_removed_values?
      grid_removed_values = {}

    output = []

    values = value

    if _.isArray(values) and values.length > 0
      for value in values
        schema_value = grid_values[value] or grid_removed_values[value]
        text = schema_value?.txt
        bg_color = schema_value?.bg_color

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

    {grid_values, grid_removed_values} = schema

    if not grid_values?
      grid_values = {}

    if not grid_removed_values?
      grid_removed_values = {}

    output = []

    values = value

    if _.isArray(values) and values.length > 0
      for value in values
        schema_value = grid_values[value] or grid_removed_values[value]
        if (text = schema_value?.txt)?
          output.push text

    return output.join ", "
