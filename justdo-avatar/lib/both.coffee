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

  isAvatarNotSetOrBase64Svg: (user) ->
    if _.isString user
      user = Meteor.users.findOne user, {fields: {"profile.profile_pic": 1}}
    
    if not user?
      throw new Meteor.Error "unknown-user"

    return not user.profile?.profile_pic? or @isAvatarBase64Svg user.profile?.profile_pic

  isAvatarBase64Svg: (avatar_url) ->
    return avatar_url?.startsWith @getBase64SvgPrefix() 

  base64SvgAvatarToElement: (avatar_url) ->
    if not @isAvatarBase64Svg avatar_url
      return
    
    avatar_url = avatar_url.replace @getBase64SvgPrefix(), ""

    $svg = $(window.atob(avatar_url))
    return $svg
  
  # Extract avatar background and foreground colors from a base64 svg URI
  # Returns an object of the following structure:
  # {
  #   avatar_bg: "#000000",
  #   avatar_fg: "#000000"
  # }
  #
  # Returns undefined if the avatar is not a base64 svg
  extractColorsFromBase64Svg: (avatar_url) ->
    if not @isAvatarBase64Svg avatar_url
      return
    
    avatar_url = avatar_url.replace @getBase64SvgPrefix(), ""
    
    svg_str = ""
    if Meteor.isServer
      svg_str = Buffer.from(avatar_url, "base64").toString()
    if Meteor.isClient
      svg_str = window.atob(avatar_url)
    
    # Extract background color from circle fill attribute
    # For proxy users, there are two circles - the first with fill="none" and the second with the actual color
    # So we need to find a circle with fill that's not "none", or get the last circle's fill value
    bg_matches = svg_str.match(/<circle[^>]*fill="([^"]+)"/g) || []
    avatar_bg = null
    
    if bg_matches.length > 0
      # Try to find a circle with fill that's not "none"
      for match in bg_matches
        color_match = match.match(/fill="([^"]+)"/)
        color = color_match?[1]
        if color? and color isnt "none"
          avatar_bg = color
          break
      
      # If we didn't find a non-none fill, use the last one
      if not avatar_bg? and bg_matches.length > 0
        last_match = bg_matches[bg_matches.length - 1]
        last_color_match = last_match.match(/fill="([^"]+)"/)
        avatar_bg = last_color_match?[1]
    
    # Extract foreground color from text fill attribute
    fg_match = svg_str.match(/<text[^>]*fill="([^"]+)"/)
    avatar_fg = fg_match?[1]
    
    return {avatar_bg, avatar_fg}

  getCachedInitialAvatarDetails: (user) ->
    # Check for the image stored in the user's profile.
    # And returns an object of the following structure:
    #
    # {
    #    profile_pic_field_defined: true/false
    #    # The following fields are only relevant if profile_pic_field_defined is true
    #    is_base64_svg_avatar: true/false
    #
    #    # Note: avatar_colors will be undefined when either is_base64_svg_avatar is false or profile_pic_field_defined is false
    #    avatar_colors: {
    #        avatar_bg: "#000000",
    #        avatar_fg: "#000000"
    #    }
    # }


    if _.isString user
      user = Meteor.users.findOne user, {fields: {"profile.profile_pic": 1}}
    if not user?
      throw new Meteor.Error "unknown-user"
    
    is_profile_pic_field_defined = user?.profile?.profile_pic?

    ret = 
      profile_pic_field_defined: is_profile_pic_field_defined

    if not is_profile_pic_field_defined
      return ret

    if @isUserAvatarBase64Svg user
      ret.avatar_colors = @extractColorsFromBase64Svg user.profile.profile_pic
      ret.is_base64_svg_avatar = true
    else
      ret.is_base64_svg_avatar = false
    
    return ret
  
  isUserCachedInitialAvatarColorsSameAsGeneratedAvatarColors: (user) ->
    cached_avatar_details = @getCachedInitialAvatarDetails user
    cached_avatar_colors = cached_avatar_details?.avatar_colors

    if not cached_avatar_colors?
      return false

    # No options should be passed to getInitialsSvgColors, since we want to generate the colors based on the user's email.
    generated_avatar_colors = @getInitialsSvgColors JustdoHelpers.getUserMainEmail(user)

    is_fg_same = cached_avatar_colors?.avatar_fg is generated_avatar_colors.avatar_fg
    is_bg_same = cached_avatar_colors?.avatar_bg is generated_avatar_colors.avatar_bg

    return is_fg_same and is_bg_same
