default_bg_color = JustdoHelpers.normalizeBgColor("#4285f4")
default_fg_color = JustdoHelpers.getFgColor(default_bg_color)

GridControl.installFormatter "tagsFormatter",
  slick_grid: ->
    {schema, doc, path, value} = @getFriendlyArgs()

    field_value = value
    value = null

    formatter_options = schema.grid_column_formatter_options

    if (valuesGenerator = formatter_options?.valuesGenerator)?
      value = valuesGenerator(doc)
    else
      value = field_value

    output = []

    if _.isArray(value) and value.length > 0
      for tag in value
        if (propertiesGenerator = formatter_options?.propertiesGenerator)?
          properties = propertiesGenerator(tag)

          {text, text_i18n, bg_color, fg_color, jd_tt_template} = properties

        if (not text?) and (not text_i18n?)
          text = value
        else
          text = APP.justdo_i18n.getI18nTextOrFallback {i18n_key: text_i18n, fallback_text: text}

        if not bg_color?
          # Note will also affect cases where propertiesGenerator(tag) returned [] / [undefined, "x"]
          bg_color = default_bg_color

        bg_color = JustdoHelpers.normalizeBgColor(bg_color)

        if not fg_color?
          # Note will also affect cases where propertiesGenerator(tag) returned [] / ["x", undefined]

          if bg_color?
            fg_color = JustdoHelpers.getFgColor(bg_color)
          else
            fg_color = default_fg_color

        custom_style = """ style="background-color: #{JustdoHelpers.xssGuard(bg_color)}; color: #{JustdoHelpers.xssGuard(fg_color)};" """

        jd_tt_html = ""
        if jd_tt_template?
          jd_tt_html = """ jd-tt="#{JustdoHelpers.xssGuard(jd_tt_template, {allow_html_parsing: false, enclosing_char: '"'})}" """

        output.push """
          <div class="tag-wrapper" #{custom_style} #{jd_tt_html}>#{JustdoHelpers.xssGuard(text)}</div>
        """

    return """<div class="grid-formatter tag-formatter">#{output.join(" ")}</div>"""

  print: ->
    {schema, doc, path, value} = @getFriendlyArgs()

    field_value = value
    value = null

    formatter_options = schema.grid_column_formatter_options

    if (valuesGenerator = formatter_options?.valuesGenerator)?
      value = valuesGenerator(doc)
    else
      value = field_value

    output = []

    if _.isArray(value) and value.length > 0
      for tag in value
        if (propertiesGenerator = formatter_options?.propertiesGenerator)?
          properties = propertiesGenerator(tag)

          {text, text_i18n} = properties

        if (not text?) and (not text_i18n?)
          text = value
        else
          text = APP.justdo_i18n.getI18nTextOrFallback {i18n_key: text_i18n, fallback_text: text}

          output.push text

    return output.join ", "
