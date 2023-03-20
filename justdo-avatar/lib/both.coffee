JustdoAvatar = {}

_.extend JustdoAvatar,
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
