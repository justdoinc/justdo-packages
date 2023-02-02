_.extend JustdoAccounts.prototype,
  getAvatarUploadType: ->
    env_vars = APP.env_rv.get()

    if not _.isEmpty env_vars?.FILESTACK_KEY
      return "filestack"

    if env_vars?.JUSTDO_FILES_ENABLED is "true"
      return "justdo_files"

    return

  getAvatarUploadPolicy: (cb) ->
    Meteor.call 'accounts_avatars_getAvatarUploadPolicy', cb

  setFilestackAvatar: (filepicker_blob, policy, cb) ->
    Meteor.call 'accounts_avatars_setFilestackAvatar', filepicker_blob, policy, cb

  # Code taken from image-file-resize NPM package
  # https://github.com/ibnYusrat/image-file-resize/
  resizeAvatarImage: (file, width, height, type) ->
    return new Promise (resolve, reject) ->
      allowed_formats = [
        "jpg"
        "gif"
        "bmp"
        "png"
        "jpeg"
        "svg"
      ]
      try
        if file.name and file.name.split(".").reverse()[0] and allowed_formats.includes(file.name.split(".").reverse()[0].toLowerCase()) and file.size and file.type
          type = type or "png"
          width = width or "auto"
          height = height or "auto"

          if width is "auto" and height is "auto"
            throw new Error("Please define width or height")

          file_name = file.name
          reader = new FileReader()
          reader.readAsDataURL file
          reader.onload = (e) ->
            img = new Image()
            img.src = e.target.result

            img.onload = ->
              canvas = document.createElement "canvas"

              if width isnt "auto" and height isnt "auto"
                canvas.width = width
                canvas.height = height
              else if width isnt "auto"
                canvas.width = width
                canvas.height = img.height * width / img.width
              else if height isnt "auto"
                canvas.height = height
                canvas.width = img.width * height / img.height

              ctx = canvas.getContext("2d")
              ctx.drawImage img, 0, 0, canvas.width, canvas.height

              canvas.toBlob (blob) =>
                resized_img = new File [blob], file_name,
                  type: "image/#{type.toLowerCase()}"
                  lastModified: Date.now()

                resolve resized_img
                return

          reader.onerror = (err) -> reject err
        else
          reject "File not supported!"
      catch error
        console.log "Error while image resize: ", error
        reject error
      return

  uploadNewAvatar: (img_file, cb) ->
    if _.isFunction img_file
      cb = img_file

    if not cb?
      cb = -> return

    # Use Filestack for avatar upload if it's enabled
    if APP.filestack_base?
      @getAvatarUploadPolicy (error, policy) =>
        if error?
          @logger.error error

          return cb(error)

        pick_options =
          policy: policy.policy
          signature: policy.signature
          storeLocation: 'S3'
          storePath: @_getAvatarUploadPath Meteor.userId()
          storeAccess: 'public'
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
      return

    if APP.justdo_files?
      @resizeAvatarImage img_file, 250, 250
        .then (resized_img) =>
          try
            upload = APP.justdo_files.avatars_collection.insert
              file: resized_img
              meta:
                is_avatar: true
              streams: "dynamic"
              chunkSize: "dynamic"
              transport: "ddp"
            , false
          catch err
            @logger.error err
            cb(err)

          upload.on "end", (err, file_obj) =>
            if err?
              @logger.error err
              cb(err)
              return

            APP.justdo_files.removeOldAvatars {exclude: file_obj._id}, (err) =>
              if err?
                @logger.error err
                cb(err)
                return

              user_id = Meteor.userId()

              avatar_link = APP.justdo_files.avatars_collection.findOne({userId: user_id}).link()
              Meteor.users.update(user_id, {$set: {"profile.profile_pic": avatar_link}})
              cb(undefined)
              return

            return

          upload.start()

          return
        .catch (err) =>
          @logger.error err
          cb(err)
          return

      return

    message = "Filestack and Justdo Files are not enabled."

    @logger.error message

    return cb(message)

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
