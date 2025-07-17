_.extend JustdoAvatar,
  applyCachedAvatarUpdate: (mongo_modifiers_obj = {}, user_doc, forced_user_settings = {}) ->
    # Returns the edited mongo_modifiers_obj (if not provided, a new one will be created)
    #
    # For behavior details, see below.
    #
    # Arguments:
    #
    # mongo_modifiers_obj: edited in place.
    #
    # A mongo modifiers object, if not provided, a new one will be created.
    #
    # See behavior below for more details.
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
    #
    # *Note, that if all of these settings are provided, the user_doc is effectively ignored.*
    #
    # Behavior:
    #
    # A reminder:
    #
    # - Generated avatar colors are the colors that are derived from the user's email first character.
    # - Cached avatar colors are the colors that are derived from the user's profile picture (assuming that it is an SVG of a user initials avatar).
    # - We are running the assumption that the profile.avatar_bg and profile.avatar_fg are the cached avatar colors (if there is cache).
    #
    # XXX COMPLETE THIS PART
    # 1. If the user isn't using an avatar initials - do nothing.
    # 2. IN ALL OTHER CASES, we will re-genrate the avatar and will ensure that the fg and bg colors are the same as the generated avatar.
    #
    # 1. If mongo_modifiers_obj not provided, a new one will be created with the following fields:

    email = forced_user_settings.email or JustdoHelpers.getUserMainEmail user_doc
    first_name = forced_user_settings.first_name or user_doc.profile.first_name
    last_name = forced_user_settings.last_name or user_doc.profile.last_name
    is_proxy = if forced_user_settings.is_proxy? then forced_user_settings.is_proxy else APP.accounts.isProxyUser(user_doc)
    
    # From this moment on, user_doc

    # Create a new mongo_modifiers_obj if none was provided
    if not mongo_modifiers_obj.$set?
      mongo_modifiers_obj.$set = {}
    
    get_initial_svg_options =
      is_proxy: is_proxy
    
    # If the user's avatar color has been modified, those colors should be used for the new avatar 
    # regardless of whether the email has changed
    is_user_avatar_color_same_as_generated = @isUserCachedInitialAvatarColorsSameAsGeneratedAvatarColors user_doc
    if not is_user_avatar_color_same_as_generated
      if (user_avatar_bg = user_doc.profile.avatar_bg)? and (user_avatar_fg = user_doc.profile.avatar_fg)?
        get_initial_svg_options.avatar_bg = user_avatar_bg # XXX CONVERT TO USE THE CACHED COLORS
        get_initial_svg_options.avatar_fg = user_avatar_fg
    
    new_avatar = @getInitialsSvg email, first_name, last_name, get_initial_svg_options
    avatar_colors = @getInitialsSvgColors email, get_initial_svg_options
    
    mongo_modifiers_obj.$set["profile.profile_pic"] = new_avatar
    mongo_modifiers_obj.$set["profile.avatar_bg"] = avatar_colors.avatar_bg
    mongo_modifiers_obj.$set["profile.avatar_fg"] = avatar_colors.avatar_fg
    
    return mongo_modifiers_obj

