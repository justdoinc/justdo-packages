_.extend JustdoAvatar,
  applyCachedAvatarUpdate: (mongo_modifiers_obj = {}, user_doc, forced_user_settings = {}) ->
    # If a user is using Cached Avatar, ensure that it is congruent to the user_doc and forced_user_settings.
    # If it isn't congruent according to the Order of Precedence set below, update the mongo_modifiers_obj
    # with the correct new avatar and colors.
    #
    # Returns the edited mongo_modifiers_obj (if not provided, a new one will be created).
    #
    # Terminology:
    #
    # - Generated avatar colors are the colors that are derived from the user's email first character (check `getInitialsSvgColors` for details).
    # - Cached avatar colors are the colors that are derived from the user's profile picture (assuming that it is an SVG of a user initials avatar).
    #
    # Order of precedence for deciding the right avatar colors:
    #
    # 1. If profile.profile_pic is set but not initials svg, we consider the case as no-colors.
    # 2. If profile.profile_pic is set and is initials svg, we consider them as the colors.
    # 3. If profile.profile_pic is not set at all, but we got fg/bg colors, we consider them as the colors.
    # 4. Otherwise, we use the generated avatar colors as the colors.
    #
    # Arguments:
    #
    # mongo_modifiers_obj: (edited in place) A mongo modifiers object, if not provided, a new one will be created.
    #
    # user_doc: REQUIRED! assumed to be the current user_doc (to avoid refetching) - this function
    # isn't meant for the process of registration, but rather for the process of updating a user's
    # avatar.
    #
    # forced_user_settings, an object that can have one of the following keys:
    #   
    # - email: a string, the email to use for the avatar
    # - first_name: a string, the first name to use for the avatar
    # - last_name: a string, the last name to use for the avatar
    # - is_proxy: a boolean, whether the user is a proxy
    #
    # If any of the above keys are provided, they will override the user's actual settings in user_doc.

    # Obtain user_cached_avatar_details
    user_cached_avatar_details = @getCachedInitialAvatarDetails user_doc

    # If the user has an avatar but it's not base64 svg, do nothing.
    if user_cached_avatar_details.profile_pic_field_defined and not user_cached_avatar_details.is_base64_svg_avatar 
      return mongo_modifiers_obj

    # Prepare variables from forced_user_settings or user_doc
    email = forced_user_settings.email or JustdoHelpers.getUserMainEmail user_doc
    first_name = forced_user_settings.first_name or user_doc.profile.first_name
    last_name = forced_user_settings.last_name or user_doc.profile.last_name
    is_proxy = if forced_user_settings.is_proxy? then forced_user_settings.is_proxy else APP.accounts.isProxyUser(user_doc)

    # Figure the right fg/bg colors for the user
    fg = undefined
    bg = undefined

    if not user_cached_avatar_details.profile_pic_field_defined
      # First, try to get them from the user document
      fg = user_doc?.profile?.avatar_fg
      bg = user_doc?.profile?.avatar_bg      

      if not fg? or not bg?
        # Fallback to the generated avatar colors
        if not fg?
          fg = Settings.text_color # If only bg is available, use the default fg.
        if not bg?
          bg = JustdoAvatar.getInitialsSvgColors(email).avatar_bg
    else
      # Check whether the user's EXISTING cached avatar colors are the same as the generated avatar colors.
      # If they are not, use the cached avatar colors for the new avatar.
      is_user_avatar_color_same_as_generated = @isUserCachedInitialAvatarColorsSameAsGeneratedAvatarColors user_doc

      if is_user_avatar_color_same_as_generated
        initials_svg_colors = JustdoAvatar.getInitialsSvgColors(email)
        # In this case - the user never set his own custom colors - keep using the Generated Colors (even if the email changed, which will cause change of color)
        fg = initials_svg_colors.avatar_fg
        bg = initials_svg_colors.avatar_bg
      else
        fg = user_cached_avatar_details.avatar_colors.avatar_fg
        bg = user_cached_avatar_details.avatar_colors.avatar_bg

    # Generate the new avatar
    get_initial_svg_options =
      is_proxy: is_proxy
      avatar_fg: fg
      avatar_bg: bg
    
    new_avatar = @getInitialsSvg email, first_name, last_name, get_initial_svg_options

    # Update the mongo_modifiers_obj
    updates_obj_extended_set_modifier = {}

    if user_doc.profile.profile_pic != new_avatar
      updates_obj_extended_set_modifier["profile.profile_pic"] = new_avatar
    if user_doc.profile.avatar_fg != fg
      updates_obj_extended_set_modifier["profile.avatar_fg"] = fg
    if user_doc.profile.avatar_bg != bg
      updates_obj_extended_set_modifier["profile.avatar_bg"] = bg

    if not _.isEmpty updates_obj_extended_set_modifier
      mongo_modifiers_obj.$set = _.extend {}, mongo_modifiers_obj.$set, updates_obj_extended_set_modifier
    
    return mongo_modifiers_obj

