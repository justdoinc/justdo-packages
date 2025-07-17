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
    # Behavior:
    #
    # 1. If the user isn't using an avatar initials - do nothing.
    # 2. If mongo_modifiers_obj not provided, an empty object will be created.
    # 3. if mongo_modifiers_obj.$set is not provided, it will be created. 
    # 4. A new avatar will be generated. If the user's cached avatar colors are different from the generated avatar colors,
    #    the new avatar will have the same colors as the cached avatar (e.g. The avatar initials will be updated when the user's name changes, while the color stays the same).
    # 5. mongo_modifiers_obj will be updated with the new avatar and colors.
    # 
    # A reminder:
    #
    # - Generated avatar colors are the colors that are derived from the user's email first character (check `getInitialsSvgColors` for details).
    # - Cached avatar colors are the colors that are derived from the user's profile picture (assuming that it is an SVG of a user initials avatar).

    # Obtain user_cached_avatar_details
    user_cached_avatar_details = @getCachedInitialAvatarDetails user_doc
    is_user_avatar_defined = user_cached_avatar_details.profile_pic_field_defined
    is_user_avatar_base64_svg = user_cached_avatar_details.is_base64_svg_avatar

    # If the user has an avatar but it's not base64 svg, do nothing.
    # This means either the user has uploaded their own avatar, or the avatar is set from OAuth.
    # In both cases, we don't want to regenerate the avatar.
    if is_user_avatar_defined and not is_user_avatar_base64_svg 
      return mongo_modifiers_obj

    # Prepare variables from forced_user_settings or user_doc
    email = forced_user_settings.email or JustdoHelpers.getUserMainEmail user_doc
    first_name = forced_user_settings.first_name or user_doc.profile.first_name
    last_name = forced_user_settings.last_name or user_doc.profile.last_name
    is_proxy = if forced_user_settings.is_proxy? then forced_user_settings.is_proxy else APP.accounts.isProxyUser(user_doc)
    
    get_initial_svg_options =
      is_proxy: is_proxy
    
    # If the user's avatar color has been modified, ensure that the regenerated avatar has the same colors as the cached avatar.
    # Note that if the user doesn't have an avatar at all, `avatar_colors` will not exist.
    is_cached_avatar_colors_available = not _.isEmpty user_cached_avatar_details.avatar_colors
    if is_cached_avatar_colors_available
      get_initial_svg_options.avatar_bg = user_cached_avatar_details.avatar_colors.avatar_bg
      get_initial_svg_options.avatar_fg = user_cached_avatar_details.avatar_colors.avatar_fg
    
    new_avatar = @getInitialsSvg email, first_name, last_name, get_initial_svg_options
    avatar_colors = @getInitialsSvgColors email, get_initial_svg_options

    # Create a new mongo_modifiers_obj if none was provided
    if not mongo_modifiers_obj.$set?
      mongo_modifiers_obj.$set = {}

    mongo_modifiers_obj.$set["profile.profile_pic"] = new_avatar
    mongo_modifiers_obj.$set["profile.avatar_bg"] = avatar_colors.avatar_bg
    mongo_modifiers_obj.$set["profile.avatar_fg"] = avatar_colors.avatar_fg
    
    return mongo_modifiers_obj

