formatDecimals = (decimal) ->
  if not decimal?
    return ""

  return JustdoMathjs.math.format(decimal, {precision: 2, notation: "fixed"}).replace(/\.0+$/, "")

GridControl.installFormatter "defaultFormatter",
  defaultHoverCaption: (friendly_args) -> undefined

  defaultFooter: (friendly_args) -> undefined

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

    custom_classes = ""
    if (customClasses = friendly_args.formatter_options?.customClasses)
      custom_classes = customClasses(friendly_args) or ""

    html_comment = undefined
    if (htmlCommentGenerator = friendly_args.formatter_options?.htmlCommentGenerator)
      html_comment = htmlCommentGenerator(friendly_args)

      if not _.isString(html_comment) or html_comment.trim() == ""
        html_comment = undefined

    comment_jd_tt = ""
    if html_comment?
       comment_jd_tt = """ jd-tt="html?tt-pos_my=left%20top&tt-pos_at=right%2B2px%20top&html=#{encodeURIComponent(html_comment)}" """

    formatter = """
      <div class="grid-formatter default-formatter #{custom_classes} "#{if custom_style != "" then " style=\"#{custom_style}\"" else ""}#{if (caption = formatter_obj.defaultHoverCaption(friendly_args))? then " title=\"#{JustdoHelpers.xssGuard(caption)}\"" else ""} dir="auto">#{value}#{if (footer = formatter_obj.defaultFooter(friendly_args))? then """<div class="default-formatter-footer text-muted">
        #{JustdoHelpers.xssGuard(footer)}</div>""" else ""}
        #{if html_comment? then """<div class="comment-indicator" #{comment_jd_tt}>◥</div>""" else ""}
      </div>
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
