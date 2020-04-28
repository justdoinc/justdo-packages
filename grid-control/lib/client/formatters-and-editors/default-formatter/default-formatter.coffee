formatDecimals = (decimal) ->
  if not decimal?
    return ""

  return JustdoMathjs.math.format(decimal, {precision: 2, notation: "fixed"}).replace(/\.0+$/, "")

GridControl.installFormatter "defaultFormatter",
  defaultHoverCaption: (friendly_args) -> undefined

  valueTransformation: (value) -> value

  slick_grid: ->
    custom_style = ""

    friendly_args = @getFriendlyArgs()

    {schema, value, formatter_obj, self} = friendly_args

    if not value?
      value = ""
    else
      value = formatter_obj.valueTransformation(value)

      if (grid_ranges = schema.grid_ranges)?
        value_range = null
        for range_def in grid_ranges
          if not (range = range_def.range)?
            console.warn "A range definition without range property detected, this shouldn't happen, please check"
          else
            [min, max] = range

            if not min? and not max?
              value_range = range_def
            else if not min? and max >= value
              value_range = range_def
            else if not max? and min <= value
              value_range = range_def
            else if min <= value and max >= value
              value_range = range_def

            if value_range?
              break

        if value_range?
          if (bg_color = value_range.bg_color)?
            bg_color = JustdoHelpers.normalizeBgColor(bg_color)

            if bg_color != "transparent"
              custom_style += """background-color: #{bg_color}; color: #{JustdoHelpers.getFgColor(bg_color)};"""

      if schema.type is Number
        custom_style += " text-align: right;"
        if schema.decimal is true
          value = formatDecimals(value)

      value = self.xssGuard value

      value = linkifyHtml value,
        nl2br: @options.allow_dynamic_row_height
        linkClass: "jd-underline font-weight-bold text-body"

    formatter = """
      <div class="grid-formatter default-formatter"#{if custom_style != "" then " style=\"#{custom_style}\"" else ""}#{if (caption = formatter_obj.defaultHoverCaption(friendly_args))? then " title=\"#{JustdoHelpers.xssGuard(caption)}\"" else ""} dir="auto">#{value}</div>
    """

    return formatter

  print: (doc, field, path) ->
    {value, schema, formatter_obj} = @getFriendlyArgs()

    value = formatter_obj.valueTransformation(value)

    if schema.type is Number and schema.decimal is true
      return formatDecimals(value)

    if _.isNumber value
      return "" + value

    return value