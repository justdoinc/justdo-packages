is_alphanumeric_reg = /^[a-z0-9]/i

_.extend JustdoAvatar,
  # create an avatar profile pic with initial of user's first name and last name
  getInitialsSvg: (email, first_name, last_name, options) ->
    {avatar_bg, avatar_fg} = @getInitialsSvgColors(email, options)

    alphanumeric_name = is_alphanumeric_reg.test(first_name) and is_alphanumeric_reg.test(last_name)
    if not alphanumeric_name
      return Settings.fallback_url

    initials = first_name.charAt(0).toUpperCase() + last_name.charAt(0).toUpperCase()

    svg = ""
    svg_cx = Settings.svg_width / 2
    svg_cy = Settings.svg_height / 2
    svg_r = Settings.svg_width / 2
    svg_r_offset = 2

    svg = """
      <svg xmlns="http://www.w3.org/2000/svg" pointer-events="none" width="#{Settings.svg_width}" height="#{Settings.svg_height}">
    """

    if options.is_proxy
      svg += """
        <circle cx="#{svg_cx}" cy="#{svg_cy}" r="#{svg_r}" fill="none"
          style="
            stroke: #546e7a;
            stroke-width: 3px;
            stroke-dasharray: 2 5;
            stroke-linecap: round;
            stroke-linejoin: round;" />
        <circle cx="#{svg_cx}" cy="#{svg_cy}" r="#{svg_r - svg_r_offset}" fill="#{avatar_bg}"
          style="stroke: white; stroke-width: 1.5px;" />
      """
    else
      svg += """<circle cx="#{svg_cx}" cy="#{svg_cy}" r="#{svg_r}" fill="#{avatar_bg}" />"""

    svg += """
        <text x="50%" y="50%" dy="0.4em" font-family="#{Settings.font_family}" fill="#{avatar_fg}" pointer-events="auto" text-anchor="middle" style="font-weight:400; font-size:#{Settings.font_size}px;">
          #{initials}
        </text>
      </svg>
    """

    base_64_svg = Buffer.from(unescape(encodeURIComponent(svg))).toString("base64")

    return "data:image/svg+xml;base64,#{base_64_svg}"
