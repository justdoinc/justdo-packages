is_alphanumeric_reg = /^[a-z0-9]/i

_.extend JustdoAvatar,
  avatar_required_fields: JustdoHelpers.avatar_required_fields

  getAvatarHtml: (user_doc) ->
    return """<img class="justdo-avatar" src="#{JustdoHelpers.xssGuard(JustdoAvatar.showUserAvatarOrFallback(user_doc))}" title="#{JustdoHelpers.xssGuard(JustdoHelpers.displayName(user_doc))}" />"""

  # create an avatar profile pic with initial of user's first name and last name
  getInitialsSvg: (email, first_name, last_name, options) ->
    {avatar_bg, avatar_fg} = @getInitialsSvgColors(email, options)

    alphanumeric_name = is_alphanumeric_reg.test(first_name) and is_alphanumeric_reg.test(last_name)
    if not alphanumeric_name
      return Settings.fallback_url

    initials = first_name.charAt(0).toUpperCase() + last_name.charAt(0).toUpperCase()
    element = $('<text text-anchor="middle"></text>').attr(
      "x": "50%"
      "y": "50%"
      "dy": "0.4em"
      "pointer-events": "auto"
      "fill": avatar_fg
      "font-family": Settings.font_family
    ).html(initials).css(
      "font-weight": 400
      "font-size": "#{Settings.font_size}px"
    )

    svg = ""
    svg_cx = Settings.svg_width / 2
    svg_cy = Settings.svg_height / 2
    svg_r = Settings.svg_width / 2
    svg_r_offset = 2

    if options?.is_proxy
      svg += """
        <svg>
          <circle cx="#{svg_cx}" cy="#{svg_cy}" r="#{svg_r}" fill="none"
            style="
              stroke: #546e7a;
              stroke-width: 3px;
              stroke-dasharray: 2 5;
              stroke-linecap: round;
              stroke-linejoin: round;" />
          <circle cx="#{svg_cx}" cy="#{svg_cy}" r="#{svg_r - svg_r_offset}" fill="#{avatar_bg}"
            style="stroke: white; stroke-width: 1.5px;" />
        </svg>
      """
    else
      svg += """<svg><circle cx="#{svg_cx}" cy="#{svg_cy}" r="#{svg_r}" fill="#{avatar_bg}" /></svg>"""

    $svg = $(svg).attr(
      "xmlns": "http://www.w3.org/2000/svg"
      "pointer-events": "none"
      "width": Settings.svg_width
      "height": Settings.svg_height
    )

    $svg.append element
    svg_html = window.btoa(unescape(encodeURIComponent($("<div>").append($svg.clone()).html())))

    return "data:image/svg+xml;base64,#{svg_html}"

justdo_avatar_helpers =
  avatar_url: ->
    if _.isObject @profile
      # We assume that if profile is object we are within a Meteor.users
      # doc context
      return JustdoAvatar.showUserAvatarOrFallback(@)

    return JustdoAvatar.showAvatarOrFallback(@profile_pic, @email, @first_name, @last_name)

  title_name: ->
    if _.isObject @profile
      return "#{@profile.first_name} #{@profile.last_name}"
    else
      title = ""

      if @first_name?
        title += "#{@first_name}"

      if @last_name?
        title += " #{@last_name}"

      return title

  user_id: ->
    return @_id

Template.justdo_avatar.helpers justdo_avatar_helpers

Template.justdo_avatar_no_tooltip.helpers justdo_avatar_helpers
