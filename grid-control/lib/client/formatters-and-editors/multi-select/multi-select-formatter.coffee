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
          <div class="multi-select-wrapper" #{custom_style}>#{JustdoHelpers.xssGuard(text)}</div>
        """

    return """<div class="grid-formatter multi-select-formatter">#{output.join(" ")}</div>"""

  slick_grid_jquery_events: [
    {
      args: ["click", ".multi-select-formatter"] # Click anywhere in the cell basically
      handler: (e) ->
        @editEventCell e, (editor_object) ->
          return

        return
    }
  ]

  print_formatter_produce_html: true

  print: ->
    {schema, value: values} = @getFriendlyArgs()

    {grid_values, grid_removed_values} = schema

    if not grid_values?
      grid_values = {}

    if not grid_removed_values?
      grid_removed_values = {}

    ret = ""

    if values?.length > 0
      for value in values
        if not value?
          # Regard undefined value as empty string (we don't return immediately to
          # allow the user set a html/txt labels for empty/undefined values)
          value = ""

        if not (value_by_formats = grid_values[value])?
          # Try look for the value in grid_removed_values
          if not (value_by_formats = grid_removed_values[value])?
            return value

        if not (bg_color = value_by_formats.bg_color)?
          bg_color = default_bg_color

        if (txt_format = value_by_formats.txt)?
          val = txt_format
        else
          val = value

        ret += """
          <div class="justdo-color-picker-color-option-wrapper mb-2"><div class="justdo-color-picker-color-option border-0" style="background-color: ##{JustdoHelpers.xssGuard(bg_color.replace(/^#/, ""))}"></div>#{JustdoHelpers.xssGuard(val)}</div>
        """

    return ret
