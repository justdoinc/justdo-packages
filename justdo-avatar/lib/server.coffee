_.extend JustdoAvatar,
  # Apply avatar update to a mongo modifiers object when a user's name or email is changed
  # Returns the modified mongo_modifiers_obj with avatar updates if needed
  applyCachedAvatarUpdate: (mongo_modifiers_obj, user_doc, options = {}) ->
    email = options.email or JustdoHelpers.getUserMainEmail user_doc
    first_name = options.first_name or user_doc.profile.first_name
    last_name = options.last_name or user_doc.profile.last_name
    is_proxy = if options.is_proxy? then options.is_proxy else APP.accounts.isProxyUser(user_doc)
    
    # Create a new mongo_modifiers_obj if none was provided
    if not mongo_modifiers_obj.$set?
      mongo_modifiers_obj.$set = {}
    
    get_initial_svg_options =
      is_proxy: is_proxy
    
    # If the user's avatar color has been modified, those colors should be used for the new avatar 
    # regardless of whether the email has changed
    is_user_avatar_color_same_as_generated = @isUserCachedInitialAvatarColorsSameAsGeneratedAvatarColors user_doc
    if not is_user_avatar_color_same_as_generated
      if (user_avatar_bg = user_doc.profile.avatar_bg) and (user_avatar_fg = user_doc.profile.avatar_fg)
        get_initial_svg_options.avatar_bg = user_avatar_bg
        get_initial_svg_options.avatar_fg = user_avatar_fg
    
    new_avatar = @getInitialsSvg email, first_name, last_name, get_initial_svg_options
    avatar_colors = @getInitialsSvgColors email, get_initial_svg_options
    
    mongo_modifiers_obj.$set["profile.profile_pic"] = new_avatar
    mongo_modifiers_obj.$set["profile.avatar_bg"] = avatar_colors.avatar_bg
    mongo_modifiers_obj.$set["profile.avatar_fg"] = avatar_colors.avatar_fg
    
    return mongo_modifiers_obj

