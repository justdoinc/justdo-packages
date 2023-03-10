Template._loginDropdownAvatarArea.helpers
  avatarUploadUsingFilestackAllowed: ->
    return APP.accounts.getAvatarUploadType() is "filestack"

  avatarUploadUsingJustdoFilesAllowed: ->
    return APP.accounts.getAvatarUploadType() is "justdo_files"

  userHasProfilePic: ->
    return JustdoHelpers.userHasProfilePic(Meteor.user({fields: {"profile.profile_pic": 1}}))

  getProfilePic: ->
    return JustdoAvatar.showUserAvatarOrFallback(@)

  currentUserAvatarFields: -> Meteor.user({fields: JustdoAvatar.avatar_required_fields})

activeUploadProcess = ->
  return $(".dropdown-avatar").hasClass("loading")

Template._loginDropdownAvatarArea.events
  "click .upload-new-profile-pic, change .upload-new-profile-pic-with-justdo-files": (e) ->
    if not _.isString(avatar_upload_type = APP.accounts.getAvatarUploadType())
      return

    if activeUploadProcess()
      console.log "Upload process already taking place"

      return

    $dropdown_avatar = $(".dropdown-avatar")
    $dropdown_avatar.addClass("loading")

    if avatar_upload_type is "justdo_files"
      if not (file = e.currentTarget?.files?[0])?
        $dropdown_avatar.removeClass("loading")
        return

    APP.accounts.uploadNewAvatar file, (err) ->
      if err?
        JustdoSnackbar.show
          text: err
        APP.logger.error "Upload failed", err

      $dropdown_avatar.removeClass("loading")

      return

    return

  "click .remove-profile-pic": ->
    if activeUploadProcess()
      APP.logger.debug "Can't remove avatar during upload process"

      return

    bootbox.confirm
      className: "bootbox-new-design"
      title: "Profile Picture Remove"
      message: "Are you sure you want to remove your profile picture?"
      buttons:
        cancel: label: "Cancel"
        confirm: label: "Confirm"
      callback: (result) ->
        if result
          Meteor.users.update(Meteor.userId(), {$unset: {"profile.profile_pic": ""}})

        return

    return
