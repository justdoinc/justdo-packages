_.extend JustdoAccounts.prototype,
  isAvatarUploadEnabled: ->
    return not _.isEmpty(APP.env_rv.get()?.FILESTACK_KEY)

  getAvatarUploadPolicy: (cb) ->
    Meteor.call 'accounts_avatars_getAvatarUploadPolicy', cb

  setFilestackAvatar: (filepicker_blob, policy, cb) ->
    Meteor.call 'accounts_avatars_setFilestackAvatar', filepicker_blob, policy, cb

  uploadNewAvatar: (cb) ->
    if not cb?
      cb = -> return

    if not APP.filestack_base?
      message = "Filestack not enabled (APP.filestack_base is null)."

      @logger.error message

      return cb(message)

    @getAvatarUploadPolicy (error, policy) =>
      if error?
        @logger.error error

        return cb(error)

      pick_options = 
        policy: policy.policy
        signature: policy.signature
        maxFiles: 1
        maxSize: 5 * 1024 * 1024 # 5 mega byte
        multiple: false
        mimetype: 'image/*'
        services: [
          'COMPUTER',
          'WEBCAM',
          'FACEBOOK',
          'GMAIL',
          'FLICKR',
          'GOOGLE_DRIVE',
          'PICASA',
          'WEBCAM',
          'INSTAGRAM',
          'CONVERT'
        ]
        cropForce: true
        cropRatio: 1
        cropMin: [40, 40]
        conversions: ['crop', 'rotate']

      pickFailureCB = (FPError) =>
        message = FPError.toString()

        @logger.error message

        return cb(message)

      pickSuccessCB = (pickedBlob) =>
        @logger.debug "Conversion in progress..."

        convert_options = 
          width: 250,
          height: 250,
          fit: 'crop',
          align: 'faces'
          format: 'png'
          compress: true
          policy: policy.policy
          signature: policy.signature

        store_options =
          location: "S3"
          path: @_getAvatarUploadPath Meteor.userId()
          access: "public"

        convertFailureCB = (FPError) =>
          message = FPError.toString()
          @logger.error message

          return cb(message)

        convertSuccessCB = (convertedBlob) =>
          @setFilestackAvatar convertedBlob, policy, (error) =>
            if error?
              @logger.error error

              cb(error)

              # don't return, so we'll still remove the picked blob.

          filepicker.remove pickedBlob, policy, =>
            @logger.debug "Removed Original File"

            cb(undefined)

        filepicker.convert pickedBlob, convert_options, store_options, convertSuccessCB, convertFailureCB

      APP.filestack_base.filepicker.pick pick_options, pickSuccessCB, pickFailureCB

  isInitialsAvatarsUpdateNecessary: (old_profile, modified_profile) ->
    if not old_profile? or not modified_profile?
      # Too edge case, we don't deal with it
      @logger.debug "initials-avatar-update-skipped-due-to-wrong-input"

      return false

    modified_profile_pic = modified_profile.profile_pic
    if not modified_profile_pic?
      # If profile pic doesn't exists, set it to the initals avatar
      return true
    else if modified_profile_pic.substr(0, 4) == "http"
      # If profile pic links to a web url - no need to generate
      # initials cache.
      #
      # Note that the anonymous user avatar is a relative path,
      # so no need to worry about not replacing it in case the
      # user set first name/last name that we can generate
      # initials for.

      return false

    old_first_name = old_profile.first_name
    modified_first_name = modified_profile.first_name

    old_last_name = old_profile.last_name
    modified_last_name = modified_profile.last_name

    if old_first_name[0] != modified_first_name[0] or
       old_last_name[0] != modified_last_name[0]
      return true

    old_avatar_fg = old_profile.avatar_fg
    modified_avatar_fg = modified_profile.avatar_fg

    old_avatar_bg = old_profile.avatar_bg
    modified_avatar_bg = modified_profile.avatar_bg

    if old_avatar_fg != modified_avatar_fg or
       old_avatar_bg != modified_avatar_bg
      return true

    return false

  updateInitialsAvatarIfNecessary: (old_profile, modified_profile) ->
    if @isInitialsAvatarsUpdateNecessary(old_profile, modified_profile)
      @updateCachedInitialsAvatar()

    return

  updateCachedInitialsAvatar: ->
    user_doc = Meteor.user()

    avatar = JustdoAvatar.getUserInitialsSvg user_doc

    Meteor.users.update Meteor.userId(), {$set: {"profile.profile_pic": avatar}}, =>
      @logger.debug "Cached user initials avatar updated"

    return

  isPasswordFlowPermittedForCurrentUser: (cb) ->
    @isPasswordFlowPermittedForUser(JustdoHelpers.currentUserMainEmail(), cb)

    return

  destroy: ->
    if @destroyed
      @logger.debug "Destroyed already"

      return

    @destroyed = true

    @login_state_tracker.stop()

    @logger.debug "Destroyed"
