Template._loginDropdownAvatarArea.helpers
  avatarUploadAllowed: ->
    return APP.accounts.isAvatarUploadEnabled()

  userHasProfilePic: ->
    return JustdoHelpers.userHasProfilePic(Meteor.user())

  getProfilePic: ->
    return JustdoAvatar.showUserAvatarOrFallback(@)

activeUploadProcess = ->
  return $(".dropdown-avatar").hasClass("loading")

Template._loginDropdownAvatarArea.events
  "click .upload-new-profile-pic": ->
    if not APP.accounts.isAvatarUploadEnabled()
      return

    if activeUploadProcess()
      console.log "Upload process already taking place"

      return

    $dropdown_avatar = $(".dropdown-avatar")
    $dropdown_avatar.addClass("loading")
    APP.accounts.uploadNewAvatar (err) ->
      if err?
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
