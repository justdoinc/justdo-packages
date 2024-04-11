JustdoAvatar = {}

is_alphanumeric_reg = /^[a-z0-9]/i

base64_svg_prefix = "data:image/svg+xml;base64,"

extractUserAvatarParams = (user_doc) ->
  email = user_doc.emails?[0]?.address
  profile = user_doc.profile

  profile_pic = profile.profile_pic
  first_name = profile.first_name
  last_name = profile.last_name

  options = {avatar_bg: profile.avatar_bg, avatar_fg: profile.avatar_fg, is_proxy: user_doc.is_proxy}

  return {profile_pic, email, first_name, last_name, options}

_.extend JustdoAvatar,
  getBase64SvgPrefix: ->
    return base64_svg_prefix

  # check if an avatar exists, if not generate initials avatar, fallback to anonymous for non English inputs
  showAvatarOrFallback: (avatar_url, email, first_name, last_name, options) ->
    if avatar_url?
      # If avatar_url is defined but userHasProfilePic returns false, assume avatar_url to be base64 image string.
      if not JustdoHelpers.userHasProfilePic {profile: {profile_pic: avatar_url}}
        return avatar_url

      if (client_type = JustdoHelpers.getClientType(env)) is "web-app"
        return JustdoHelpers.getCDNUrl avatar_url

      # As of the time of writing, landing app isn't aware of the CDN domain of web app.
      # Therefore in cases where avatar_url is a path (i.e. the avatar is uploaded to justdo-files),
      # we need to append the WEB_APP_ROOT_URL as the domain, since files inside justdo-files are served on web app only.
      if JustdoHelpers.getClientType(env) is "landing-app"
        # If avatar_url begins with "/", assume it's a path.
        # Construct a full URL with WEB_APP_ROOT_URL and return.
        if avatar_url.substr(0, 1) is "/"
          return new URL(avatar_url, env.WEB_APP_ROOT_URL).toString()

        # Else assume avatar_url is already a full url. Simply return.
        return avatar_url

    if first_name? and last_name?
      return @getInitialsSvg email, first_name, last_name, options

    return Settings.fallback_url

  showUserAvatarOrFallback: (user_doc) ->
    if not _.isObject(user_doc) or not _.isObject(user_doc.profile)
      return Settings.fallback_url

    {profile_pic, email, first_name, last_name, options} = extractUserAvatarParams(user_doc)

    return @showAvatarOrFallback profile_pic, email, first_name, last_name, options

  #
  # Initials generators
  #
  getUserInitialsSvg: (user_doc) ->
    {profile_pic, email, first_name, last_name, options} = extractUserAvatarParams(user_doc)

    return @getInitialsSvg(email, first_name, last_name, options)

  getInitialsSvgColors: (email, options) ->
    # Get background color
    avatar_bg = options?.avatar_bg
    if not avatar_bg?
      if email? and email != ""
        avatar_bg_color_index = Math.floor(email.charCodeAt(0) % Settings.colors.length)
      else
        avatar_bg_color_index = 0

      avatar_bg = Settings.colors[avatar_bg_color_index]

    # Get foreground color
    avatar_fg = options?.avatar_fg or Settings.text_color

    return {avatar_bg, avatar_fg}

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

    if options?.is_proxy
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
        <text
          x="50%" y="50%" dy="0.4em"
          font-family="#{Settings.font_family}"
          fill="#{avatar_fg}"
          pointer-events="auto"
          text-anchor="middle"
          style="
            font-weight:400;
            font-size:#{Settings.font_size}px;">
          #{initials}
        </text>
      </svg>
    """

    if Meteor.isServer
      base_64_svg = Buffer.from(unescape(encodeURIComponent(svg))).toString("base64")
    if Meteor.isClient
      base_64_svg = window.btoa(unescape(encodeURIComponent(svg)))

    return "#{@getBase64SvgPrefix()}#{base_64_svg}"

  isUserAvatarBase64Svg: (user) ->
    if _.isString user
      user = Meteor.users.findOne user, {fields: {"profile.profile_pic": 1}}
      
    return @isAvatarBase64Svg user?.profile?.profile_pic

  isAvatarBase64Svg: (avatar_url) ->
    return avatar_url?.startsWith @getBase64SvgPrefix() 

  base64SvgAvatarToElement: (avatar_url) ->
    if not @isAvatarBase64Svg avatar_url
      return
    
    avatar_url = avatar_url.replace @getBase64SvgPrefix(), ""

    $svg = $(window.atob(avatar_url))
    return $svg